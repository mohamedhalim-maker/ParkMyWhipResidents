import 'package:get_it/get_it.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_manager.dart';
import 'package:park_my_whip_residents/src/features/auth/data/supabase_auth_manager.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/forgot_password/forgot_password_cubit.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Helpers
  getIt.registerLazySingleton<SharedPrefHelper>(() => SharedPrefHelper());

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
