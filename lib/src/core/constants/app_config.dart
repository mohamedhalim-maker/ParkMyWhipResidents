/// Application configuration constants for multi-app architecture
class AppConfig {
  AppConfig._();

  /// The app ID for this specific application
  /// This should match the app ID in the Supabase `apps` table
  static const String appId = 'park_my_whip_resident';

  /// Human-readable app name
  static const String appName = 'Park My Whip - Resident';

  /// Deep link scheme for this app
  static const String deepLinkScheme = 'parkmywhip-resident';
}
