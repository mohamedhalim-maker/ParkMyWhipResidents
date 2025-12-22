import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/login_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/signup_pages/signup_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/signup_pages/verify_email_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/signup_pages/set_password_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/forgot_password_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_link_sent_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_link_error_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_password_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/password_reset_success_page.dart';
import 'package:park_my_whip_residents/src/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:park_my_whip_residents/src/features/splash/presentation/pages/splash_page.dart';
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
      case RoutesName.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
        );

      case RoutesName.login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<LoginCubit>(),
            child: const LoginPage(),
          ),
        );

      case RoutesName.signup:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<SignupCubit>(),
            child: const SignupPage(),
          ),
        );

      case RoutesName.verifyEmail:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<SignupCubit>(),
            child: const VerifyEmailPage(),
          ),
        );

      case RoutesName.setPassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<SignupCubit>(),
            child: const SetPasswordPage(),
          ),
        );

      case RoutesName.dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        );

      case RoutesName.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ForgotPasswordCubit>(),
            child: const ForgotPasswordPage(),
          ),
        );

      case RoutesName.resetLinkSent:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ForgotPasswordCubit>(),
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
            value: getIt<ForgotPasswordCubit>(),
            child: const ResetPasswordPage(),
          ),
        );

      case RoutesName.passwordResetSuccess:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ForgotPasswordCubit>(),
            child: const PasswordResetSuccessPage(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Text('No route defined for ${settings.name}'),
              ),
            ),
          ),
        );
    }
  }
}
