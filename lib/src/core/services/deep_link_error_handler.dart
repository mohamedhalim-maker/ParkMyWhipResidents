import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/routes/router.dart';

/// Handles deep link errors before Supabase processes them.
///
/// **Purpose:**
/// Intercepts password reset links that contain error parameters
/// (expired, invalid, or already used) and navigates to error page
/// BEFORE Supabase tries to process them.
///
/// **Why this is needed:**
/// Supabase automatically processes deep links when the app opens.
/// If a reset link is expired/invalid, Supabase would try to process it
/// and fail silently or show generic errors. This handler catches those
/// errors early and shows a user-friendly error page.
///
/// **How it works:**
/// 1. App opens with deep link (password reset URL)
/// 2. This handler intercepts the URL before Supabase
/// 3. Checks for error parameters in URL (error, error_code, error_description)
/// 4. If error found → navigate to error page
/// 5. If no error → let Supabase handle normally (PASSWORD_RECOVERY event)
class DeepLinkErrorHandler {
  static final _appLinks = AppLinks();

  /// Setup deep link error interceptor.
  ///
  /// **Checks for errors in:**
  /// - Query parameters: ?error=...&error_description=...
  /// - Fragment parameters: #error=...&error_description=...
  ///
  /// **Common error codes:**
  /// - 'otp_expired': Reset link has expired
  /// - 'invalid_request': Link is malformed or invalid
  /// - 'access_denied': Link was already used or revoked
  static void setup() {
    _appLinks.uriLinkStream.listen(
      (uri) {
        AppLogger.deepLink('Deep link received: ${uri.toString()}');

        // Check query parameters for errors
        final hasQueryError = uri.queryParameters.containsKey('error') ||
            uri.queryParameters.containsKey('error_code');

        // Check fragment for errors (Supabase uses fragment for auth callbacks)
        bool hasFragmentError = false;
        Map<String, String> fragmentParams = {};
        if (uri.fragment.isNotEmpty) {
          fragmentParams = Uri.splitQueryString(uri.fragment);
          hasFragmentError = fragmentParams.containsKey('error') ||
              fragmentParams.containsKey('error_code');
        }

        // Extract error details for logging and display
        if (hasQueryError || hasFragmentError) {
          final errorCode = uri.queryParameters['error'] ??
              uri.queryParameters['error_code'] ??
              fragmentParams['error'] ??
              fragmentParams['error_code'] ??
              'unknown_error';

          final errorDescription = uri.queryParameters['error_description'] ??
              fragmentParams['error_description'] ??
              'Email link is invalid or has expired';

          AppLogger.auth(
            '⚠️ Invalid/expired link detected | '
            'Code: $errorCode | '
            'Message: $errorDescription',
          );

          // Navigate to error page BEFORE Supabase processes the link
          // Use post-frame callback to ensure navigation context is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = AppRouter.navigatorKey.currentContext;
            if (context != null && context.mounted) {
              AppLogger.navigation(
                'Navigating to reset link error page (clearing stack)',
              );
              Navigator.of(context).pushNamedAndRemoveUntil(
                RoutesName.resetLinkError,
                (route) => false,
              );
            } else {
              AppLogger.warning(
                'Navigation context not available for error page',
              );
            }
          });
        } else {
          AppLogger.deepLink(
            '✓ Valid deep link - letting Supabase handle it',
          );
        }
      },
      onError: (error) {
        AppLogger.error(
          'Deep link stream error',
          error: error,
        );
      },
    );
  }
}
