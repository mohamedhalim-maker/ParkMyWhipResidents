/// Authentication and database constants
/// Centralized location for all auth-related constant values
class AuthConstants {
  AuthConstants._(); // Private constructor to prevent instantiation

  // Database table names
  static const String usersTable = 'users';
  static const String userAppsTable = 'user_apps';

  // Cache keys for SharedPreferences
  static const String userProfileCacheKey = 'user_profile';
  static const String userIdCacheKey = 'user_id';

  // Deep link schemes for email verification and password reset
  static String verifyEmailRedirectUrl(String deepLinkScheme) =>
      '$deepLinkScheme://verify-email';

  static String resetPasswordRedirectUrl(String deepLinkScheme) =>
      '$deepLinkScheme://reset-password';

  // Default user role
  static const String defaultUserRole = 'user';

  // Logger name
  static const String loggerName = 'SupabaseAuth';
}
