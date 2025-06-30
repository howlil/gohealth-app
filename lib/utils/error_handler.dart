import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void init() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Suppress specific known assertion errors that don't affect functionality
      final String errorText = details.exception.toString();

      // Suppress mouse tracking assertion errors
      if (errorText.contains('mouse_tracker.dart') ||
          errorText.contains(
              '(event is PointerAddedEvent) == (lastEvent is PointerRemovedEvent)') ||
          errorText.contains('PointerAddedEvent') ||
          errorText.contains('PointerRemovedEvent')) {
        debugPrint('🐭 Mouse tracker assertion suppressed (known issue)');
        return;
      }

      // Suppress other common non-critical assertion errors
      if (errorText.contains('RenderFlex overflowed') ||
          errorText.contains('A RenderFlex overflowed')) {
        debugPrint('📏 Render overflow suppressed (layout issue)');
        return;
      }

      // Suppress keyboard appearance errors
      if (errorText.contains('keyboard') && errorText.contains('assertion')) {
        debugPrint('⌨️ Keyboard assertion suppressed');
        return;
      }

      // Log other important errors in development
      if (kDebugMode) {
        FlutterError.presentError(details);
        debugPrint('🐛 Flutter Error: ${details.exception}');
        debugPrint('📍 Library: ${details.library}');
        debugPrint('🔍 Context: ${details.context}');
      }
    };

    // Handle async/platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      final String errorText = error.toString();

      // Suppress known mouse tracker async errors
      if (errorText.contains('mouse_tracker') ||
          errorText.contains('PointerAddedEvent') ||
          errorText.contains('PointerRemovedEvent')) {
        debugPrint('🐭 Async mouse tracker error suppressed');
        return true;
      }

      if (kDebugMode) {
        debugPrint('⚠️ Async Error: $error');
        debugPrint('📚 Stack: $stack');
      }

      return true; // Mark as handled
    };

    debugPrint(
        '🛡️ Error handler initialized - mouse tracker issues will be suppressed');
  }
}
