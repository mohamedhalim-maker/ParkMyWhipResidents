import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/services/deep_link_service.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

/// Splash page that acts as a gate to wait for deep link resolution
/// before navigating to the appropriate destination.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _resolveNavigation();
  }

  Future<void> _resolveNavigation() async {
    // Wait for deep link service to complete processing
    final deepLinkRoute = await DeepLinkService.instance.waitForDeepLinkResolution();

    if (!mounted) return;

    // If deep link provided a target route, navigate there
    if (deepLinkRoute != null) {
      AppLogger.navigation('SplashPage: Navigating to deep link route: $deepLinkRoute');
      Navigator.of(context).pushNamedAndRemoveUntil(
        deepLinkRoute,
        (route) => false,
      );
      return;
    }

    // Otherwise, check auth state and navigate to appropriate default route
    final defaultRoute = await _getDefaultRoute();
    if (!mounted) return;

    AppLogger.navigation('SplashPage: Navigating to default route: $defaultRoute');
    Navigator.of(context).pushNamedAndRemoveUntil(
      defaultRoute,
      (route) => false,
    );
  }

  Future<String> _getDefaultRoute() async {
    try {
      final session = SupabaseConfig.auth.currentSession;
      if (session != null) {
        return RoutesName.dashboard;
      }
      return RoutesName.login;
    } catch (e) {
      AppLogger.error('SplashPage: Error checking session', error: e, name: 'Navigation');
      return RoutesName.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.richRed),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                color: AppColor.gray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
