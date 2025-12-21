import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/routes/router.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService _instance = DeepLinkService._();
  static DeepLinkService get instance => _instance;

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;

  /// Setup deep linking for the app
  static Future<void> setupDeepLinking() async {
    await instance.initialize(onDeepLinkReceived: _handlePasswordResetDeepLink);
    instance._setupAuthStateListener();
  }

  /// Handle password reset deep link navigation
  static void _handlePasswordResetDeepLink(Uri uri) {
    debugPrint('Handling deep link: $uri');

    if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutesName.resetPassword,
          (route) => false,
        );
      }
    }
  }

  /// Initialize deep link handling
  Future<void> initialize({
    required Function(Uri) onDeepLinkReceived,
  }) async {
    try {
      // Handle the initial link that opened the app
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial deep link received: $initialUri');
        _handleDeepLink(initialUri, onDeepLinkReceived);
      }

      // Listen for deep links while the app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          debugPrint('Deep link received: $uri');
          _handleDeepLink(uri, onDeepLinkReceived);
        },
        onError: (error) {
          debugPrint('Deep link error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
    }
  }

  /// Setup auth state listener to handle deep link tokens
  void _setupAuthStateListener() {
    _authStateSubscription =
        SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('Auth state changed: $event');

      // When user clicks the password reset link, Supabase will automatically
      // exchange the token and trigger PASSWORD_RECOVERY event
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('Password recovery event detected');
        final context = AppRouter.navigatorKey.currentContext;
        if (context != null) {
          // Navigate to reset password page
          Navigator.of(context).pushNamedAndRemoveUntil(
            RoutesName.resetPassword,
            (route) => false,
          );
        }
      }
    });
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri, Function(Uri) onDeepLinkReceived) {
    // Check if this is a password reset link
    if (uri.scheme == 'parkmywhip-resident') {
      if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
        debugPrint('Password reset deep link received: $uri');

        // Extract the recovery token from the URL fragments
        final fragment = uri.fragment;
        if (fragment.isNotEmpty) {
          final params = Uri.splitQueryString(fragment);

          // Check for access_token and type=recovery
          final accessToken = params['access_token'];
          final type = params['type'];
          final refreshToken = params['refresh_token'];

          if (accessToken != null && type == 'recovery') {
            debugPrint('Password reset token found, verifying session...');

            // Set the session using the tokens from the deep link
            // Supabase will automatically trigger PASSWORD_RECOVERY event
            _verifyRecoveryToken(accessToken, refreshToken ?? '');
            return;
          }
        }
      }

      // For any other deep link, just call the callback
      onDeepLinkReceived(uri);
    }
  }

  /// Verify and set the recovery token session
  Future<void> _verifyRecoveryToken(
      String accessToken, String refreshToken) async {
    try {
      // Set session with the tokens from deep link
      // This will trigger the PASSWORD_RECOVERY event in auth state listener
      await SupabaseConfig.auth.setSession(accessToken);
      debugPrint('Recovery token verified successfully');
    } catch (e) {
      debugPrint('Error verifying recovery token: $e');
      // Navigate to error page if token verification fails
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutesName.resetLinkError,
          (route) => false,
        );
      }
    }
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
    _authStateSubscription?.cancel();
  }
}
