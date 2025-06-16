import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void init() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      // Suppress mouse tracking assertion errors
      if (details.exception.toString().contains('mouse_tracker.dart')) {
        return;
      }

      // Log other errors
      debugPrint('Flutter Error: ${details.exception}');
    };

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Async Error: $error');
      return true;
    };
  }
}
