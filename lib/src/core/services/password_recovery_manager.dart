import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/routes/router.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

/// Manages password recovery session security.
///
/// **Problem:**
/// When a user clicks a password reset link, Supabase creates a temporary recovery
/// session (similar to login). If the user closes the app without completing the
/// password reset, the session persists in local storage. On next app launch,
/// they would be auto-logged in and taken to dashboard with a temporary session.
///
/// **Solution:**
/// This manager uses a persistent flag to track recovery mode:
///
/// **Flow:**
/// 1. User clicks reset link → PASSWORD_RECOVERY event fires → flag set to TRUE
/// 2. User completes password reset → flag set to FALSE (user stays logged in)
/// 3. User closes app without resetting → flag remains TRUE
/// 4. App relaunches → Supabase initializes and restores session
/// 5. checkAndClearAbandonedRecoverySession() runs → sees flag=TRUE → signs out user
/// 6. User is properly logged out and must login with new credentials
///
/// **Critical:** Supabase MUST be initialized BEFORE checkAndClearAbandonedRecoverySession()
/// so that the session is restored first, then we can sign out properly.
class PasswordRecoveryManager {
  /// Check on app startup if user abandoned recovery flow and sign them out.
  ///
  /// **CRITICAL:** This must run AFTER SupabaseConfig.initialize() so that
  /// the session is restored from storage first, then we can properly sign out.
  ///
  /// **Process:**
  /// 1. Check if recovery mode flag exists and is TRUE
  /// 2. If TRUE, user abandoned password reset → sign them out immediately
  /// 3. DON'T clear flag yet - let getInitialRoute() check it first
  /// 4. Flag will be cleared after routing decision is made
  static Future<void> checkAndClearAbandonedRecoverySession() async {
    try {
      final helper = getIt<SharedPrefHelper>();
      final isRecoveryMode =
          await helper.getBool(SharedPrefStrings.isRecoveryMode) ?? false;

      AppLogger.auth('Recovery mode check - flag value: $isRecoveryMode');

      if (isRecoveryMode) {
        final session = SupabaseConfig.auth.currentSession;
        AppLogger.auth(
          '⚠️ Abandoned recovery session detected! '
          'Session exists: ${session != null}. Signing out user...',
        );

        // Sign out to clear the temporary recovery session
        await SupabaseConfig.auth.signOut();

        AppLogger.auth(
            '✓ Recovery session signed out (flag will be cleared after routing)');
      } else {
        AppLogger.auth('✓ No abandoned recovery session found');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error checking recovery mode',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear recovery mode flag after routing decision is made.
  ///
  /// **When to call:**
  /// After getInitialRoute() has checked the flag and determined the route.
  /// This ensures the flag is available for routing decision but cleaned up afterward.
  static Future<void> clearRecoveryFlagAfterRouting() async {
    try {
      final helper = getIt<SharedPrefHelper>();
      final isRecoveryMode =
          await helper.getBool(SharedPrefStrings.isRecoveryMode) ?? false;

      if (isRecoveryMode) {
        await helper.saveBool(SharedPrefStrings.isRecoveryMode, false);
        AppLogger.auth('✓ Recovery flag cleared after routing');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error clearing recovery flag',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Set recovery mode flag when PASSWORD_RECOVERY event is triggered.
  ///
  /// **When called:**
  /// - TRUE: When PASSWORD_RECOVERY event fires (user clicked reset link)
  /// - FALSE: When user successfully completes password reset
  ///
  /// **Purpose:**
  /// Tracks whether user is in the middle of a password reset flow.
  /// If app is closed while TRUE, user will be signed out on next launch.
  static Future<void> setRecoveryMode(bool isRecovery) async {
    try {
      final helper = getIt<SharedPrefHelper>();
      await helper.saveBool(SharedPrefStrings.isRecoveryMode, isRecovery);
      AppLogger.auth(
        isRecovery
            ? '🔑 Recovery mode ENABLED - user clicked password reset link'
            : '✓ Recovery mode DISABLED - user completed password reset',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to set recovery mode flag',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Listen to auth state changes and handle password recovery flow.
  ///
  /// **Triggers:**
  /// - PASSWORD_RECOVERY: When user clicks a valid password reset link
  /// - SIGNED_IN: Normal login
  /// - SIGNED_OUT: User logged out
  /// - TOKEN_REFRESHED: Session refreshed
  ///
  /// **Password Recovery Flow:**
  /// 1. User clicks reset link → Supabase validates token
  /// 2. PASSWORD_RECOVERY event fires → this listener activates
  /// 3. Set recovery flag to TRUE
  /// 4. Navigate to reset password page
  /// 5. User enters new password → flag set to FALSE (in ForgotPasswordCubit)
  /// 6. User stays logged in with new password
  static void setupAuthListener() {
    SupabaseConfig.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;

        AppLogger.auth(
          'Auth event: $event | '
          'Session exists: ${session != null}',
        );

        // Handle password recovery event
        if (event == AuthChangeEvent.passwordRecovery) {
          AppLogger.auth(
            '🔑 PASSWORD_RECOVERY event detected - '
            'User clicked valid reset link. Activating recovery mode...',
          );

          // Set recovery mode flag
          await setRecoveryMode(true);

          // Navigate to reset password page with safety checks
          final context = AppRouter.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            AppLogger.navigation(
              'Navigating to reset password page (clearing stack)',
            );
            Navigator.of(context).pushNamedAndRemoveUntil(
              RoutesName.resetPassword,
              (route) => false,
            );
          } else {
            AppLogger.warning(
              'Navigation context not available for reset password page',
            );
          }
        }
      },
      onError: (error) {
        AppLogger.error(
          'Auth state change error',
          error: error,
        );
      },
    );
  }
}
