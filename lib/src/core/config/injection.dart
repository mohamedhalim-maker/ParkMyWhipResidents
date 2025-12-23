import 'package:get_it/get_it.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_manager.dart';
import 'package:park_my_whip_residents/src/features/auth/data/supabase_auth_manager.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_cubit.dart';

final getIt = GetIt.instance;

/// Setup dependency injection for the app.
///
/// **Registration Order:**
/// 1. Helpers (no dependencies)
/// 2. Services (depend on helpers)
/// 3. Cubits (depend on services)
///
/// **Critical:** This MUST run before PasswordRecoveryManager uses SharedPrefHelper.
Future<void> setupDependencyInjection() async {
  // Helpers (no dependencies) - registered as lazy singletons
  // SharedPrefHelper is used by PasswordRecoveryManager for recovery flag storage
  getIt.registerLazySingleton<SharedPrefHelper>(() => SharedPrefHelper());

  // Initialize SharedPrefHelper cache for synchronous access
  await getIt<SharedPrefHelper>().init();

  // Auth Manager
  getIt.registerLazySingleton<AuthManager>(
    () => SupabaseAuthManager(sharedPrefHelper: getIt<SharedPrefHelper>()),
  );

  // Validators
  getIt.registerLazySingleton<Validators>(() => Validators());

  // Cubits
  getIt.registerLazySingleton<LoginCubit>(
    () => LoginCubit(
      validators: getIt<Validators>(),
      authManager: getIt<AuthManager>(),
    ),
  );

  getIt.registerLazySingleton<SignupCubit>(
    () => SignupCubit(
      validators: getIt<Validators>(),
      authManager: getIt<AuthManager>(),
    ),
  );

  getIt.registerLazySingleton<ForgotPasswordCubit>(
    () => ForgotPasswordCubit(
      validators: getIt<Validators>(),
      authManager: getIt<AuthManager>(),
    ),
  );
}
