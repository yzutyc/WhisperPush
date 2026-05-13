// import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Message {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String contentType;
  final String? group;
  final String level;
  final DateTime createdAt;
  final bool read;

  Message({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.contentType,
    this.group,
    required this.level,
    required this.createdAt,
    required this.read,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      contentType: json['content_type'] ?? 'text',
      group: json['group'],
      level: json['level'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      read: json['read'] ?? false,
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return DateFormat('MM-dd').format(createdAt);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return '刚刚';
    }
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }

  String get levelText {
    switch (level) {
      case 'timeSensitive':
        return '时间敏感';
      case 'critical':
        return '紧急';
      default:
        return '普通';
    }
  }

  Color get levelColor {
    switch (level) {
      case 'timeSensitive':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}