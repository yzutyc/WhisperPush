import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/device.dart';

class PushService {
  static const String _keyDeviceRegistered = 'device_registered';
  static const String _keyDeviceId = 'device_id';
  static const String _keyPushToken = 'push_token';
  static const String _keyPushVendor = 'push_vendor';

  static Future<String?> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.brand} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.utsname.machine;
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.computerName;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      return macInfo.computerName;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.prettyName;
    }
    return kIsWeb ? 'Web Browser' : 'Unknown Device';
  }

  Future<String> getDeviceType() async {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (kIsWeb) return 'web';
    return 'unknown';
  }

  Future<String?> detectPushVendor() async {
    if (Platform.isAndroid) {
      // 检测设备厂商
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String brand = androidInfo.brand.toLowerCase();

      if (brand.contains('huawei') || brand.contains('honor')) {
        return 'huawei';
      } else if (brand.contains('xiaomi') || brand.contains('redmi')) {
        return 'xiaomi';
      } else if (brand.contains('oppo')) {
        return 'oppo';
      } else if (brand.contains('vivo') || brand.contains('iqoo')) {
        return 'vivo';
      }
      // 默认使用 FCM
      return 'fcm';
    } else if (Platform.isIOS) {
        return 'apns';
    }
    return null;
  }

  Future<String?> getPushToken() async {
    // TODO: 实际集成各厂商推送 SDK 后实现
    // 华为 Push、小米 Push、FCM 等
    // 这里先返回占位符
    return 'mock_push_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<bool> registerDevice(ApiService apiService) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // 检查是否已注册
      bool? alreadyRegistered = prefs.getBool(_keyDeviceRegistered);
      if (alreadyRegistered == true) {
        return true;
      }

      String deviceType = await getDeviceType();
      String? deviceName = await getDeviceName();
      String? pushVendor = await detectPushVendor();
      String? pushToken = await getPushToken();

      Device device = await apiService.registerDevice(
        deviceType: deviceType,
        deviceToken: pushToken,
        deviceName: deviceName,
        pushVendor: pushVendor,
      );

      // 保存注册信息
      await prefs.setBool(_keyDeviceRegistered, true);
      await prefs.setInt(_keyDeviceId, device.id);
      if (pushToken != null) {
        await prefs.setString(_keyPushToken, pushToken);
      }
      if (pushVendor != null) {
        await prefs.setString(_keyPushVendor, pushVendor);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to register device: $e');
      return false;
    }
  }

  Future<void> unregisterDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceRegistered);
    await prefs.remove(_keyDeviceId);
    await prefs.remove(_keyPushToken);
    await prefs.remove(_keyPushVendor);
  }

  Future<bool> isDeviceRegistered() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDeviceRegistered) ?? false;
  }

  Future<int?> getRegisteredDeviceId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDeviceId);
  }
}

