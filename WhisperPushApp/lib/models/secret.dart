import 'package:intl/intl.dart';

class Secret {
  final int id;
  final int userId;
  final String? name;
  final DateTime createdAt;
  final bool isActive;

  Secret({
    required this.id,
    required this.userId,
    this.name,
    required this.createdAt,
    required this.isActive,
  });

  factory Secret.fromJson(Map<String, dynamic> json) {
    return Secret(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  String get formattedCreatedAt {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }

  String get displayName {
    return name ?? 'Secret #$id';
  }
}

class SecretWithKey extends Secret {
  final String secretKey;

  SecretWithKey({
    required super.id,
    required super.userId,
    super.name,
    required super.createdAt,
    required super.isActive,
    required this.secretKey,
  });

  factory SecretWithKey.fromJson(Map<String, dynamic> json) {
    return SecretWithKey(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
      secretKey: json['secret_key'],
    );
  }
}