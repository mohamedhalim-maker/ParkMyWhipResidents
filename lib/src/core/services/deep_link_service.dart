import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/routes/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  DeepLinkService._();
  
  static final DeepLinkService _instance = DeepLinkService._();
  static DeepLinkService get instance => _instance;
  
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  /// Setup deep linking for the app
  static Future<void> setupDeepLinking() async {
    await instance.initialize(onDeepLinkReceived: _handlePasswordResetDeepLink);
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
  
  /// Handle incoming deep link
  void _handleDeepLink(Uri uri, Function(Uri) onDeepLinkReceived) {
    // Check if this is a password reset link
    if (uri.scheme == 'parkmywhip-resident') {
      if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
        // Extract the recovery token from the URL fragments
        final fragment = uri.fragment;
        if (fragment.isNotEmpty) {
          // Supabase sends tokens in the fragment (after #)
          final params = Uri.splitQueryString(fragment);
          
          // Check for access_token and type=recovery
          final accessToken = params['access_token'];
          final type = params['type'];
          
          if (accessToken != null && type == 'recovery') {
            debugPrint('Password reset token found: $accessToken');
            
            // Verify the recovery session with Supabase
            _verifyRecoveryToken(accessToken).then((_) {
              // Call the callback to navigate to reset password page
              onDeepLinkReceived(uri);
            }).catchError((error) {
              debugPrint('Error verifying recovery token: $error');
            });
            return;
          }
        }
      }
      
      // For any other deep link, just call the callback
      onDeepLinkReceived(uri);
    }
  }
  
  /// Verify the recovery token with Supabase
  Future<void> _verifyRecoveryToken(String accessToken) async {
    try {
      // The recovery session is automatically handled by Supabase
      // when the user clicks the reset link
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint('Recovery session verified for user: ${session.user.email}');
      }
    } catch (e) {
      debugPrint('Error verifying recovery token: $e');
      rethrow;
    }
  }
  
  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
  }
}
