import 'package:get_it/get_it.dart';
import 'package:park_my_whip_residents/auth/auth_manager.dart';
import 'package:park_my_whip_residents/auth/supabase_auth_manager.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/auth_cubit.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Helpers
  getIt.registerLazySingleton<SharedPrefHelper>(() => SharedPrefHelper());

  // Auth Manager
  getIt.registerLazySingleton<AuthManager>(
    () => SupabaseAuthManager(getIt<SharedPrefHelper>()),
  );

  // Validators
  getIt.registerLazySingleton<Validators>(() => Validators());

  // Cubits
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      validators: getIt<Validators>(),
      authManager: getIt<AuthManager>(),
    ),
  );
}
