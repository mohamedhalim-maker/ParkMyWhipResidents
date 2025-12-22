import 'dart:developer';
import 'package:park_my_whip_residents/src/core/models/user_app_model.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_constants.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Repository for managing user app registrations
/// Handles all CRUD operations for the user_apps table
class UserAppRepository {
  const UserAppRepository();

  /// Fetches user's app registration
  Future<UserApp?> getUserAppRegistration(String userId, String appId) async {
    try {
      final data = await SupabaseService.selectSingle(
        AuthConstants.userAppsTable,
        filters: {
          'user_id': userId,
          'app_id': appId,
        },
      );

      if (data != null) {
        return UserApp.fromJson(data);
      }
      return null;
    } catch (e) {
      log('Failed to fetch user app registration: $e',
          name: AuthConstants.loggerName, error: e);
      return null;
    }
  }

  /// Registers a user for an app
  Future<UserApp> registerUserForApp({
    required String userId,
    required String appId,
    String? role,
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'user_id': userId,
      'app_id': appId,
      'role': role ?? AuthConstants.defaultUserRole,
      'is_active': true,
      'app_specific_data': {},
      'created_at': now,
      'updated_at': now,
    };

    final result = await SupabaseConfig.client
        .from(AuthConstants.userAppsTable)
        .insert(data)
        .select()
        .single();

    log('User registered for app successfully', name: AuthConstants.loggerName);
    return UserApp.fromJson(result);
  }

  /// Registers a user for an app, handling duplicate registration gracefully
  Future<UserApp> registerUserForAppSafe({
    required String userId,
    required String appId,
    String? role,
  }) async {
    try {
      return await registerUserForApp(
        userId: userId,
        appId: appId,
        role: role,
      );
    } on PostgrestException catch (e) {
      // Check if user is already registered (duplicate key violation)
      if (e.code == '23505') {
        log('User already registered for app, fetching existing registration',
            name: AuthConstants.loggerName);
        final existingRegistration =
            await getUserAppRegistration(userId, appId);
        if (existingRegistration != null) {
          return existingRegistration;
        }
      }
      rethrow;
    }
  }

  /// Deletes user's app registration
  Future<void> deleteUserAppRegistration(String userId, String appId) async {
    await SupabaseService.delete(
      AuthConstants.userAppsTable,
      filters: {
        'user_id': userId,
        'app_id': appId,
      },
    );
    log('User app registration deleted successfully',
        name: AuthConstants.loggerName);
  }

  /// Gets all app registrations for a user
  Future<List<UserApp>> getUserAppRegistrations(String userId) async {
    try {
      final data = await SupabaseService.select(
        AuthConstants.userAppsTable,
        filters: {'user_id': userId},
      );

      return data.map((json) => UserApp.fromJson(json)).toList();
    } catch (e) {
      log('Failed to fetch user app registrations: $e',
          name: AuthConstants.loggerName, error: e);
      return [];
    }
  }

  /// Checks if user has any app registrations
  Future<bool> hasOtherAppRegistrations(
      String userId, String currentAppId) async {
    try {
      final registrations = await getUserAppRegistrations(userId);
      return registrations.any((app) => app.appId != currentAppId);
    } catch (e) {
      log('Failed to check for other app registrations: $e',
          name: AuthConstants.loggerName, error: e);
      return false;
    }
  }

  /// Checks if user is registered and active for an app
  Future<bool> isUserActiveInApp(String userId, String appId) async {
    final registration = await getUserAppRegistration(userId, appId);
    return registration?.isActive ?? false;
  }
}
