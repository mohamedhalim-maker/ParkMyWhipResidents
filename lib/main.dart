import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/park_my_whip_resident_app.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/services/deep_link_error_handler.dart';
import 'package:park_my_whip_residents/src/core/services/password_recovery_manager.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Setup dependency injection (registers and initializes SharedPrefHelper)
  await setupDependencyInjection();
  AppLogger.info('✓ Dependency injection configured');

  // Step 2: Initialize Supabase (this restores any existing session from storage)
  // This MUST happen before checking recovery mode, otherwise sign-out won't work
  await SupabaseConfig.initialize();
  AppLogger.info('✓ Supabase initialized');

  // Step 3: Check if user abandoned password recovery flow
  // If they did, sign them out (session was restored in step 2, so sign-out will work)
  await PasswordRecoveryManager.checkAndClearAbandonedRecoverySession();

  // Step 4: Setup deep link error handler
  // Intercepts invalid/expired reset links before Supabase processes them
  DeepLinkErrorHandler.setup();
  AppLogger.info('✓ Deep link error handler configured');

  // Step 5: Setup auth state listener for password recovery events
  // Listens for PASSWORD_RECOVERY event when user clicks valid reset link
  PasswordRecoveryManager.setupAuthListener();
  AppLogger.info('✓ Auth listener configured');

  // Run app - getInitialRoute() will be called during MaterialApp build
  runApp(const ParkMyWhipResidentApp());

  // Clear recovery flag after app has started and routing decision is made
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await PasswordRecoveryManager.clearRecoveryFlagAfterRouting();
  });
}
