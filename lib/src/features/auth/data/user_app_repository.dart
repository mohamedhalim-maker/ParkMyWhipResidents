import 'dart:developer';
import 'package:park_my_whip_residents/src/core/models/user_app_model.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_constants.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

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
}
