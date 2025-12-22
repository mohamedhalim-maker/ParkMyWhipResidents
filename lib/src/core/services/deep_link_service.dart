import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
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

  /// Completer that resolves when initial deep link processing is complete.
  /// Returns the target route if a deep link was processed, null otherwise.
  Completer<String?>? _deepLinkCompleter;

  /// Whether the initial deep link has been processed
  bool _initialDeepLinkProcessed = false;

  /// The target route determined by deep link processing
  String? _pendingDeepLinkRoute;

  /// Setup deep linking for the app
  static Future<void> setupDeepLinking() async {
    instance._deepLinkCompleter = Completer<String?>();
    await instance.initialize(onDeepLinkReceived: _handlePasswordResetDeepLink);
    instance._setupAuthStateListener();
  }

  /// Wait for initial deep link resolution to complete.
  /// Returns the target route if a deep link was received, null otherwise.
  /// This should be called from the SplashPage to wait before navigation.
  Future<String?> waitForDeepLinkResolution() async {
    // If already processed, return the result immediately
    if (_initialDeepLinkProcessed) {
      return _pendingDeepLinkRoute;
    }

    // Wait for the completer to complete with a timeout
    try {
      final route = await _deepLinkCompleter?.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          AppLogger.deepLink('Timeout waiting for deep link');
          _completeDeepLinkProcessing(null);
          return null;
        },
      );
      return route;
    } catch (e) {
      AppLogger.error('Error waiting for deep link', error: e, name: 'DeepLink');
      return null;
    }
  }

  /// Mark deep link processing as complete with the given route
  void _completeDeepLinkProcessing(String? route) {
    if (_initialDeepLinkProcessed) return;
    
    _initialDeepLinkProcessed = true;
    _pendingDeepLinkRoute = route;
    
    if (_deepLinkCompleter != null && !_deepLinkCompleter!.isCompleted) {
      _deepLinkCompleter!.complete(route);
    }
  }

  /// Handle password reset deep link navigation
  static void _handlePasswordResetDeepLink(Uri uri) {
    AppLogger.deepLink('Handling deep link: $uri');

    if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
      // Check for error parameters - if present, navigate to error page
      final queryError = uri.queryParameters['error'];
      final queryErrorCode = uri.queryParameters['error_code'];
      
      String? fragmentError;
      String? fragmentErrorCode;
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(fragment);
        fragmentError = fragmentParams['error'];
        fragmentErrorCode = fragmentParams['error_code'];
      }

      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        // Navigate to error page if any error is present
        if (queryError != null || queryErrorCode != null || 
            fragmentError != null || fragmentErrorCode != null) {
          AppLogger.deepLink('Password reset link error in callback: error=$queryError, error_code=$queryErrorCode');
          Navigator.of(context).pushNamedAndRemoveUntil(
            RoutesName.resetLinkError,
            (route) => false,
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RoutesName.resetPassword,
            (route) => false,
          );
        }
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
        AppLogger.deepLink('Initial deep link received: $initialUri');
        _handleDeepLink(initialUri, onDeepLinkReceived, isInitial: true);
      } else {
        // No initial deep link - complete processing with null
        _completeDeepLinkProcessing(null);
      }

      // Listen for deep links while the app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          AppLogger.deepLink('Deep link received: $uri');
          _handleDeepLink(uri, onDeepLinkReceived, isInitial: false);
        },
        onError: (error) {
          AppLogger.error('Deep link stream error', error: error, name: 'DeepLink');
        },
      );
    } catch (e) {
      AppLogger.error('Error initializing deep links', error: e, name: 'DeepLink');
      // Complete processing with null on error
      _completeDeepLinkProcessing(null);
    }
  }

  /// Setup auth state listener to handle deep link tokens
  void _setupAuthStateListener() {
    _authStateSubscription =
        SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      AppLogger.auth('Auth state changed: $event');

      // When user clicks the password reset link, Supabase will automatically
      // exchange the token and trigger PASSWORD_RECOVERY event
      if (event == AuthChangeEvent.passwordRecovery) {
        AppLogger.auth('Password recovery event detected');
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
  /// [isInitial] - true if this is the initial deep link that opened the app
  void _handleDeepLink(Uri uri, Function(Uri) onDeepLinkReceived, {required bool isInitial}) {
    // Check if this is a password reset link
    if (uri.scheme == 'parkmywhip-resident') {
      if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
        AppLogger.deepLink('Password reset deep link received: $uri');

        // Check for error parameters in query string or fragment
        // Format: ?error=access_denied&error_code=otp_expired&error_description=...
        // or #error=access_denied&error_code=otp_expired&error_description=...
        final queryError = uri.queryParameters['error'];
        final queryErrorCode = uri.queryParameters['error_code'];
        
        // Also check fragment for errors
        String? fragmentError;
        String? fragmentErrorCode;
        final fragment = uri.fragment;
        if (fragment.isNotEmpty) {
          final fragmentParams = Uri.splitQueryString(fragment);
          fragmentError = fragmentParams['error'];
          fragmentErrorCode = fragmentParams['error_code'];
        }

        // If any error is present, navigate to error page
        if (queryError != null || queryErrorCode != null || 
            fragmentError != null || fragmentErrorCode != null) {
          AppLogger.deepLink('Password reset link error detected: error=$queryError, error_code=$queryErrorCode');
          if (isInitial) {
            // For initial deep links, set the pending route for SplashPage to handle
            _completeDeepLinkProcessing(RoutesName.resetLinkError);
          } else {
            // For runtime deep links, navigate directly
            _navigateToResetLinkError();
          }
          return;
        }

        // Extract the recovery token from the URL fragments
        if (fragment.isNotEmpty) {
          final params = Uri.splitQueryString(fragment);

          // Check for access_token and type=recovery
          final accessToken = params['access_token'];
          final type = params['type'];
          final refreshToken = params['refresh_token'];

          if (accessToken != null && type == 'recovery') {
            AppLogger.deepLink('Password reset token found, verifying session...');

            // Set the session using the tokens from the deep link
            // Supabase will automatically trigger PASSWORD_RECOVERY event
            _verifyRecoveryToken(accessToken, refreshToken ?? '', isInitial: isInitial);
            return;
          }
        }

        // If we got here with initial deep link but couldn't process it fully,
        // complete with null to let normal auth flow take over
        if (isInitial) {
          _completeDeepLinkProcessing(null);
        }
        return;
      }

      // For any other deep link, just call the callback
      if (isInitial) {
        _completeDeepLinkProcessing(null);
      }
      onDeepLinkReceived(uri);
    } else if (isInitial) {
      // Non-matching scheme, complete with null
      _completeDeepLinkProcessing(null);
    }
  }

  /// Navigate to reset link error page
  void _navigateToResetLinkError() {
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RoutesName.resetLinkError,
        (route) => false,
      );
    }
  }

  /// Verify and set the recovery token session
  /// [isInitial] - true if this is from the initial deep link that opened the app
  Future<void> _verifyRecoveryToken(
      String accessToken, String refreshToken, {required bool isInitial}) async {
    try {
      // Set session with the tokens from deep link
      // This will trigger the PASSWORD_RECOVERY event in auth state listener
      await SupabaseConfig.auth.setSession(accessToken);
      AppLogger.deepLink('Recovery token verified successfully');
      
      // For initial deep links, set pending route for SplashPage
      if (isInitial) {
        _completeDeepLinkProcessing(RoutesName.resetPassword);
      }
    } catch (e) {
      AppLogger.error('Error verifying recovery token', error: e, name: 'DeepLink');
      
      if (isInitial) {
        // For initial deep links, set error route for SplashPage to handle
        _completeDeepLinkProcessing(RoutesName.resetLinkError);
      } else {
        // For runtime deep links, navigate directly to error page
        final context = AppRouter.navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RoutesName.resetLinkError,
            (route) => false,
          );
        }
      }
    }
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
    _authStateSubscription?.cancel();
  }
}
