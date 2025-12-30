import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/login_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/signup_pages/signup_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/signup_pages/verify_email_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/signup_pages/set_password_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/signup_pages/enter_otp_code_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/forgot_password_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_link_sent_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_link_error_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/reset_password_page.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/pages/forgot_password_pages/password_reset_success_page.dart';
import 'package:park_my_whip_residents/src/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/general/general_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/claim_permit_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/user_name_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/user_type_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/claim_permit/setup_address_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/claim_permit/add_building_unit_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/claim_permit/select_permit_plan_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/claim_permit/add_vehicle_info_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/claim_permit/upload_driving_license_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/claim_permit/upload_vehicle_registration_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/claim_permit/upload_insurance_page.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/pages/claim_permit/confirm_details_page.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Get the initial route based on authentication state and recovery mode.
  ///
  /// **Priority:**
  /// 1. Check recovery mode flag FIRST (prevents race condition)
  /// 2. Check session existence
  ///
  /// **Why check recovery flag first:**
  /// When app restarts after user clicked reset link but didn't complete the flow,
  /// there's a race between sign-out (async) and route determination (sync).
  /// By checking the flag here synchronously, we guarantee user goes to login
  /// even if sign-out hasn't finished yet.
  static String getInitialRoute() {
    try {
      // CRITICAL: Check recovery mode flag FIRST before checking session
      // This prevents race condition where sign-out is still in progress
      final helper = getIt<SharedPrefHelper>();
      final isRecoveryMode =
          helper.getBoolSync(SharedPrefStrings.isRecoveryMode) ?? false;

      final session = SupabaseConfig.auth.currentSession;
      final hasSession = session != null;

      AppLogger.navigation(
        'Initial route determination | '
        'Session: $hasSession | '
        'Recovery flag: $isRecoveryMode',
      );

      // If recovery flag is set, ALWAYS go to login (abandoned recovery session)
      // This prevents the race condition where sign-out hasn't completed yet
      if (isRecoveryMode) {
        AppLogger.navigation(
          '⚠️ Recovery flag detected - forcing login route '
          '(sign-out in progress)',
        );
        return RoutesName.initial;
      }

      // Normal flow: check session
      if (hasSession) {
        AppLogger.navigation('✓ Valid session found - routing to dashboard');
        return RoutesName.dashboard;
      }

      AppLogger.navigation('No session - routing to login');
      return RoutesName.initial;
    } catch (e) {
      AppLogger.error('Error determining initial route', error: e);
      return RoutesName.initial;
    }
  }

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
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

      case RoutesName.enterOtpCode:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<SignupCubit>(),
            child: const EnterOtpCodePage(),
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
      case RoutesName.initial:
      case RoutesName.onboardingStep1:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<GeneralOnboardingCubit>(),
            child: const UserNamePage(),
          ),
        );

      case RoutesName.onboardingStep2:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<GeneralOnboardingCubit>(),
            child: const UserTypePage(),
          ),
        );

      case RoutesName.claimPermitSetupAddress:
        // Extract user data from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final firstName = args?['firstName'] as String? ?? '';
        final lastName = args?['lastName'] as String? ?? '';

        // Initialize claim permit cubit with user data
        final claimPermitCubit = getIt<ClaimPermitCubit>();
        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          claimPermitCubit.initializeWithUserData(
            firstName: firstName,
            lastName: lastName,
          );
        }

        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: claimPermitCubit,
            child: const SetupAddressPage(),
          ),
        );

      case RoutesName.claimPermitAddBuildingUnit:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ClaimPermitCubit>(),
            child: const AddBuildingUnitPage(),
          ),
        );

      case RoutesName.claimPermitSelectPermitPlan:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ClaimPermitCubit>(),
            child: const SelectPermitPlanPage(),
          ),
        );

      case RoutesName.claimPermitAddVehicleInfo:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ClaimPermitCubit>(),
            child: const AddVehicleInfoPage(),
          ),
        );

      case RoutesName.claimPermitUploadLicense:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ClaimPermitCubit>(),
            child: const UploadDrivingLicensePage(),
          ),
        );

      case RoutesName.claimPermitUploadRegistration:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ClaimPermitCubit>(),
            child: const UploadVehicleRegistrationPage(),
          ),
        );

      case RoutesName.claimPermitUploadInsurance:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ClaimPermitCubit>(),
            child: const UploadInsurancePage(),
          ),
        );

      case RoutesName.claimPermitConfirmDetails:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ClaimPermitCubit>(),
            child: const ConfirmDetailsPage(),
          ),
        );

      default:
        // FIX: Handle Supabase deep link parameters gracefully
        // When a deep link opens, Flutter tries to navigate to the URL path (e.g. /?code=...)
        // We show a loading indicator while Supabase processes the token in the background
        if (settings.name != null &&
            (settings.name!.contains('code=') ||
                settings.name!.contains('error=') ||
                settings.name!.contains('token='))) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        AppLogger.deepLink('No route defined for ${settings.name}');
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
