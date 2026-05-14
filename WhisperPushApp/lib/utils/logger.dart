import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class Logger {
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      final logTag = tag ?? 'DEBUG';
      developer.log(
        message,
        name: logTag,
        level: 0,
        time: DateTime.now(),
      );
    }
  }

  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      final logTag = tag ?? 'INFO';
      developer.log(
        message,
        name: logTag,
        level: 1,
        time: DateTime.now(),
      );
    }
  }

  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      final logTag = tag ?? 'WARN';
      developer.log(
        message,
        name: logTag,
        level: 2,
        time: DateTime.now(),
      );
    }
  }

  static void e(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      final logTag = tag ?? 'ERROR';
      developer.log(
        message,
        name: logTag,
        level: 3,
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }
  }

  static void network(String method, String url, {int? statusCode, Duration? duration}) {
    if (kDebugMode) {
      String message = '$method $url';
      if (statusCode != null) {
        message += ' [${statusCode.toString()}]';
      }
      if (duration != null) {
        message += ' (${duration.inMilliseconds}ms)';
      }
      developer.log(
        message,
        name: 'NETWORK',
        level: 1,
        time: DateTime.now(),
      );
    }
  }
}