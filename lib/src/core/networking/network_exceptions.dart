import 'dart:io';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/networking/custom_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Maps Supabase exceptions to domain exceptions
/// Only responsible for exception translation
class SupabaseExceptionMapper {
  static AppException map(dynamic error) {
    AppLogger.error('Mapping exception', name: 'ExceptionMapper', error: error);

    // If already a custom AppException, return as-is
    if (error is AppException) {
      return error;
    }

    if (error is SocketException) {
      return NetworkException(
        message: 'No internet connection',
        originalError: error,
      );
    }

    if (error is supabase.AuthException) {
      return _mapAuthException(error);
    }

    if (error is supabase.PostgrestException) {
      return _mapDatabaseException(error);
    }

    if (error is supabase.StorageException) {
      return _mapStorageException(error);
    }

    return UnknownException(message: error.toString(), originalError: error);
  }

  static AuthenticationException _mapAuthException(
    supabase.AuthException error,
  ) {
    // Keep Supabase's message if it's already clear
    final message = error.message;

    // Only override for specific unclear cases
    final userMessage = _getUserFriendlyAuthMessage(message, error.statusCode);

    return AuthenticationException(
      message: userMessage ?? message,
      code: error.statusCode,
      originalError: error,
    );
  }

  static String? _getUserFriendlyAuthMessage(String message, String? code) {
    final lowerMessage = message.toLowerCase();

    // Only map truly unclear messages
    if (lowerMessage.contains('invalid login credentials')) {
      return 'Invalid email or password';
    }

    if (code == '429') {
      return 'Too many attempts. Please try again later';
    }

    // Return null to use original message if it's already clear
    return null;
  }

  static DatabaseException _mapDatabaseException(
    supabase.PostgrestException error,
  ) {
    return DatabaseException(
      message: error.message,
      code: error.code,
      originalError: error,
    );
  }

  static AppException _mapStorageException(supabase.StorageException error) {
    return StorageException(
      message: error.message,
      code: error.statusCode,
      originalError: error,
    );
  }
}
