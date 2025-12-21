import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/routes/router.dart';
import 'package:park_my_whip_residents/src/core/widgets/error_dialog.dart';

/// Centralized exception handler for network operations
/// Translates technical errors into user-friendly messages
abstract class NetworkExceptions {
  /// Takes an exception and returns a user-friendly error message
  static String getExceptionMessage(dynamic error) {
    log('Processing error: $error', name: 'NetworkExceptions', level: 900, error: error);

    // Generic Exception with message
    if (error is Exception) {
      final errorString = error.toString();
      if (errorString.contains('Exception: ')) {
        return errorString.replaceFirst('Exception: ', '');
      }
      return errorString;
    }

    // Catch-all for unknown errors
    return 'An unexpected error occurred. Please try again.';
  }

  /// Shows an error dialog with the translated error message
  static void showErrorDialog(
    dynamic error, {
    String? title,
    VoidCallback? onDismiss,
  }) {
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) {
      log('Cannot show dialog - no context available', name: 'NetworkExceptions', level: 900);
      return;
    }

    final errorMessage = getExceptionMessage(error);
    
    showDialog(
      context: context,
      builder: (_) => ErrorDialog(
        errorMessage: errorMessage,
        title: title ?? 'Error',
        onDismiss: onDismiss,
      ),
    );
  }
}
