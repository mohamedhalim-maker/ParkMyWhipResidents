import 'package:get_it/get_it.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/core/services/supabase_user_service.dart';
import 'package:park_my_whip_residents/src/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:park_my_whip_residents/src/features/auth/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/auth_cubit.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Helpers
  getIt.registerLazySingleton<SharedPrefHelper>(() => SharedPrefHelper());

  // Services
  getIt.registerLazySingleton<SupabaseUserService>(
    () => SupabaseUserService(sharedPrefHelper: getIt<SharedPrefHelper>()),
  );

  // Validators
  getIt.registerLazySingleton<Validators>(() => Validators());

  // Data Sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => SupabaseAuthRemoteDataSource(
      supabaseUserService: getIt<SupabaseUserService>(),
    ),
  );

  // Cubits
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      validators: getIt<Validators>(),
      authRemoteDataSource: getIt<AuthRemoteDataSource>(),
    ),
  );
}
