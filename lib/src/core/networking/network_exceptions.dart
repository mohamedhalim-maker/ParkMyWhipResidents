import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/routes/router.dart';
import 'package:park_my_whip_residents/src/core/widgets/error_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized exception handler for network operations
/// Translates technical errors into user-friendly messages
abstract class NetworkExceptions {
  /// Takes a Supabase exception and returns a user-friendly error message
  static String getSupabaseExceptionMessage(dynamic error) {
    log('Processing error: $error', name: 'NetworkExceptions', level: 900, error: error);

    // Network connectivity issues (cross-platform check)
    final errorLower = error.toString().toLowerCase();
    if (errorLower.contains('socketexception') ||
        errorLower.contains('network is unreachable') ||
        errorLower.contains('connection refused')) {
      return 'No internet connection. Please check your network settings.';
    }

    // Supabase Auth exceptions
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    }

    // Supabase Database (Postgrest) exceptions
    if (error is PostgrestException) {
      return _getPostgrestErrorMessage(error);
    }

    // Supabase Storage exceptions
    if (error is StorageException) {
      return _getStorageErrorMessage(error);
    }

    // Generic Exception with message
    if (error is Exception) {
      final errorString = error.toString();
      if (errorString.contains('Exception: ')) {
        return errorString.replaceFirst('Exception: ', '');
      }
      return errorString;
    }

    // Catch-all for unknown errors - show the actual error
    final errorString = error.toString();
    return errorString.isNotEmpty ? errorString : 'An unexpected error occurred. Please try again.';
  }

  /// Maps Supabase AuthException to user-friendly messages
  static String _getAuthErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();
    final statusCode = error.statusCode;

    log('Auth error - Code: $statusCode, Message: ${error.message}', name: 'NetworkExceptions', level: 900);

    // Common auth error patterns
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('email not confirmed') ||
        message.contains('email not verified') ||
        message.contains('user not confirmed')) {
      return 'Invalid email or password. If you just signed up, please verify your email first.';
    }

    if (message.contains('email not confirmed') ||
        message.contains('email not verified')) {
      return 'Please verify your email address before logging in.';
    }

    if (message.contains('user not found') ||
        message.contains('user does not exist')) {
      return 'No account found with this email.';
    }

    if (message.contains('email already registered') ||
        message.contains('user already registered')) {
      return 'This email is already registered. Try logging in.';
    }

    if (message.contains('weak password') ||
        message.contains('password is too weak')) {
      return 'Password is too weak. Use at least 6 characters.';
    }

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('user is disabled') ||
        message.contains('account has been disabled')) {
      return 'This account has been disabled. Contact support.';
    }

    if (message.contains('too many requests') ||
        statusCode == '429') {
      return 'Too many attempts. Please try again later.';
    }

    if (message.contains('network') || message.contains('timeout')) {
      return 'Network error. Check your internet connection.';
    }

    if (message.contains('session not found') ||
        message.contains('refresh token not found')) {
      return 'Your session has expired. Please login again.';
    }

    if (message.contains('password mismatch')) {
      return 'Passwords do not match.';
    }

    // OTP related errors
    if (message.contains('invalid otp') ||
        message.contains('otp expired') ||
        message.contains('token has expired')) {
      return 'Invalid or expired OTP. Please request a new one.';
    }

    if (message.contains('otp not found')) {
      return 'OTP not found. Please request a new verification code.';
    }

    if (message.contains('email rate limit exceeded')) {
      return 'Too many emails sent. Please wait before requesting a new code.';
    }

    // Signup specific errors
    if (message.contains('user already exists')) {
      return 'An account with this email already exists. Try logging in.';
    }

    if (message.contains('signup disabled')) {
      return 'Signup is currently disabled. Please try again later.';
    }

    if (message.contains('email provider')) {
      return 'Email service is temporarily unavailable. Please try again.';
    }

    if (message.contains('captcha') || message.contains('verification failed')) {
      return 'Verification failed. Please try again.';
    }

    if (message.contains('database') || message.contains('insert')) {
      return 'Failed to save user data. Please try again.';
    }

    if (message.contains('new password should be different from the old password')) {
      return 'New password should be different from the old password.';
    }

    // Return the actual error message from Supabase
    return error.message.isNotEmpty
        ? error.message
        : 'Authentication failed. Please check your information and try again.';
  }

  /// Maps Supabase PostgrestException to user-friendly messages
  static String _getPostgrestErrorMessage(PostgrestException error) {
    final message = error.message?.toLowerCase() ?? '';
    final code = error.code;

    log('Database error - Code: $code, Message: ${error.message}', name: 'NetworkExceptions', level: 900);

    if (code == '23505') {
      return 'This record already exists in the database.';
    }

    if (code == '23503') {
      return 'Cannot delete this record as it is referenced by other data.';
    }

    if (code == '42501' || message.contains('permission denied') || message.contains('policy')) {
      return 'Permission denied. This might be due to Row Level Security (RLS) policies in your Supabase database. Please check your database policies.';
    }

    if (code == 'PGRST116' || message.contains('not found')) {
      return 'Requested data could not be found.';
    }

    if (code == '42P01' || message.contains('does not exist')) {
      return 'Database table does not exist. Please ensure your database schema is set up correctly.';
    }

    if (message.contains('timeout') || message.contains('deadline exceeded')) {
      return 'Operation timed out. Please try again.';
    }

    if (message.contains('connection')) {
      return 'Database connection error. Please try again.';
    }

    if (message.contains('violates')) {
      return 'Data validation failed. Please check your input.';
    }

    // Return the actual database error message
    return error.message?.isNotEmpty == true
        ? error.message!
        : 'Database operation failed. Please try again.';
  }

  /// Maps Supabase StorageException to user-friendly messages
  static String _getStorageErrorMessage(StorageException error) {
    final message = error.message?.toLowerCase() ?? '';
    final statusCode = error.statusCode;

    log('Storage error - Code: $statusCode, Message: ${error.message}', name: 'NetworkExceptions', level: 900);

    if (statusCode == '404' || message.contains('not found')) {
      return 'File not found in storage.';
    }

    if (statusCode == '401' || message.contains('unauthorized')) {
      return 'You\'re not authorized to perform this storage operation.';
    }

    if (message.contains('canceled')) {
      return 'Storage operation was canceled.';
    }

    if (message.contains('size') || message.contains('too large')) {
      return 'File is too large to upload.';
    }

    if (message.contains('quota') || message.contains('limit')) {
      return 'Storage quota exceeded.';
    }

    // Return the actual storage error message
    return error.message?.isNotEmpty == true
        ? error.message!
        : 'Storage operation failed. Please try again.';
  }

  /// Shows an error dialog with the translated error message
  /// Use this when there's no UI space to display inline error messages
  /// 
  /// Example usage:
  /// ```dart
  /// try {
  ///   await someBackendOperation();
  /// } catch (e) {
  ///   NetworkExceptions.showErrorDialog(e);
  /// }
  /// ```
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

    final errorMessage = getSupabaseExceptionMessage(error);
    
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
