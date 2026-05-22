import 'package:intl/intl.dart';

class Device {
  final int id;
  final int userId;
  final String deviceType;
  final String? deviceToken;
  final String? deviceName;
  final String? pushVendor;
  final DateTime createdAt;
  final bool isActive;

  Device({
    required this.id,
    required this.userId,
    required this.deviceType,
    this.deviceToken,
    this.deviceName,
    this.pushVendor,
    required this.createdAt,
    required this.isActive,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      userId: json['user_id'],
      deviceType: json['device_type'],
      deviceToken: json['device_token'],
      deviceName: json['device_name'],
      pushVendor: json['push_vendor'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_type': deviceType,
      'device_token': deviceToken,
      'device_name': deviceName,
      'push_vendor': pushVendor,
    };
  }

  String get formattedCreatedAt {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }

  String get vendorDisplayName {
    switch (pushVendor) {
      case 'huawei':
        return '华为推送';
      case 'xiaomi':
        return '小米推送';
      case 'oppo':
        return 'OPPO推送';
      case 'vivo':
        return 'VIVO推送';
      case 'fcm':
        return 'FCM';
      case 'apns':
        return 'APNs';
      default:
        return pushVendor ?? deviceType;
    }
  }

  String get deviceTypeDisplayName {
    switch (deviceType.toLowerCase()) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'web':
        return 'Web';
      case 'windows':
        return 'Windows';
      case 'macos':
        return 'macOS';
      case 'linux':
        return 'Linux';
      default:
        return deviceType;
    }
  }
}

