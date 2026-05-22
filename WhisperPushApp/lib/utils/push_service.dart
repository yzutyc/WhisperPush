import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huawei_push/huawei_push.dart';
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
    String? pushVendor = await detectPushVendor();

    try {
      if (pushVendor == 'huawei' && Platform.isAndroid) {
        // 华为推送
        debugPrint('尝试获取华为推送 token...');

        // 获取华为推送 token - call without await since it returns void
        try {
          // getToken requires a scope parameter, use empty string
          Push.getToken('');
          // Token will be delivered via onNewTokenStream listener
          debugPrint('华为推送 getToken 已调用，等待 token...');

          // For now, use fallback while we wait for token via stream
          return await _getFallbackToken();
        } catch (e) {
          debugPrint('获取华为推送 token 出错: $e');
          return await _getFallbackToken();
        }
      } else {
        // 其他厂商或平台，使用备用方案
        debugPrint('非华为设备或非 Android 平台，使用备用 token 方案');
        return await _getFallbackToken();
      }
    } catch (e) {
      debugPrint('获取推送 token 失败: $e');
      return await _getFallbackToken();
    }
  }

  Future<String?> _getFallbackToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 检查是否已有保存的 token
    String? savedToken = prefs.getString(_keyPushToken);
    if (savedToken != null && savedToken.isNotEmpty) {
      return savedToken;
    }

    // 生成临时 token
    String fallbackToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('使用备用 token: $fallbackToken');
    return fallbackToken;
  }

  Future<bool> initializePush() async {
    try {
      if (Platform.isAndroid) {
        // 初始化华为推送

        // 设置华为推送监听 - use only supported methods
        Push.onMessageReceivedStream.listen((RemoteMessage message) {
          debugPrint('收到推送消息: ${message.data}');
          _handlePushMessage(message);
        });

        // Use MultiAgent for other streams if available, or just log
        try {
          Push.getTokenStream.listen((String token) {
            debugPrint('华为推送新 Token 生成: $token');
            _handleNewToken(token);
          });
        } catch (e) {
          debugPrint('无法监听 token 流: $e');
        }

        debugPrint('华为推送初始化完成');
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('初始化推送服务失败: $e');
      return false;
    }
  }

  void _handlePushMessage(RemoteMessage message) {
    debugPrint('处理推送消息: ${message.toMap()}');
    // 在这里处理推送消息的显示和处理逻辑
  }

  Future<void> _handleNewToken(String token) async {
    debugPrint('处理新的 token: $token');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? oldToken = prefs.getString(_keyPushToken);

    if (oldToken != token) {
      // Token 更新了，需要同步到服务器
      await prefs.setString(_keyPushToken, token);

      // 如果设备已注册，更新 token
      bool? isRegistered = prefs.getBool(_keyDeviceRegistered);
      if (isRegistered == true) {
        int? deviceId = prefs.getInt(_keyDeviceId);
        debugPrint('Token 更新，设备 ID: $deviceId');
        // 这里可以添加更新服务器 token 的逻辑
      }
    }
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

    // 华为推送注销
    if (Platform.isAndroid) {
      try {
        // deleteToken requires scope parameter
        await Push.deleteToken('');
        debugPrint('华为推送 token 已注销');
      } catch (e) {
        debugPrint('注销华为推送 token 失败: $e');
      }
    }
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
