import 'package:park_my_whip_residents/src/core/constants/strings.dart';

/// Authentication and database constants
/// Centralized location for all auth-related constant values
class AuthConstants {
  AuthConstants._(); // Private constructor to prevent instantiation

  // Database table names
  static const String usersTable = DatabaseStrings.usersTable;
  static const String userAppsTable = DatabaseStrings.userAppsTable;

  // Cache keys for SharedPreferences
  static const String userProfileCacheKey =
      SharedPrefStrings.userProfileCacheKey;
  static const String userIdCacheKey = SharedPrefStrings.userIdCacheKey;

  // Deep link schemes for email verification and password reset
  static String verifyEmailRedirectUrl(String deepLinkScheme) =>
      AuthStrings.verifyEmailRedirectUrl(deepLinkScheme);

  static String resetPasswordRedirectUrl(String deepLinkScheme) =>
      AuthStrings.resetPasswordRedirectUrl(deepLinkScheme);

  // Default user role
  static const String defaultUserRole = AuthStrings.defaultUserRole;

  // Logger name
  static const String loggerName = AppStrings.authLoggerName;
}
