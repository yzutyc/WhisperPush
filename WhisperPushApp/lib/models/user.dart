import 'package:intl/intl.dart';

class User {
  final int id;
  final String username;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get formattedCreatedAt {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }
}
