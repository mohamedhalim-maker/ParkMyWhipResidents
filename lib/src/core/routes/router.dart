import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/login_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/forgot_password_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_link_sent_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_link_error_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_password_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/password_reset_success_page.dart';
import 'package:park_my_whip_residents/src/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<String> getInitialRoute() async {
    try {
      final session = SupabaseConfig.auth.currentSession;
      if (session != null) {
        return RoutesName.dashboard;
      }
      return RoutesName.login;
    } catch (e) {
      return RoutesName.login;
    }
  }

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<AuthCubit>(),
            child: const LoginPage(),
          ),
        );

      case RoutesName.dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        );

      case RoutesName.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<AuthCubit>(),
            child: const ForgotPasswordPage(),
          ),
        );

      case RoutesName.resetLinkSent:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<AuthCubit>(),
            child: const ResetLinkSentPage(),
          ),
        );

      case RoutesName.resetLinkError:
        return MaterialPageRoute(
          builder: (_) => const ResetLinkErrorPage(),
        );

      case RoutesName.resetPassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<AuthCubit>(),
            child: const ResetPasswordPage(),
          ),
        );

      case RoutesName.passwordResetSuccess:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<AuthCubit>(),
            child: const PasswordResetSuccessPage(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Padding(
                padding:  EdgeInsets.symmetric(vertical: 20,horizontal: 20),
                child: Text('No route defined for ${settings.name}'),
              ),
            ),
          ),
        );
    }
  }
}
