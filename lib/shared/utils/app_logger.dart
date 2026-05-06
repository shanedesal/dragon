import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void d(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    developer.log(message, name: tag, error: error, stackTrace: stackTrace);
  }
}
