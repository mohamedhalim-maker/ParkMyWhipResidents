import 'dart:developer';
import 'package:park_my_whip_residents/src/core/models/user_app_model.dart';
import 'package:park_my_whip_residents/src/core/models/user_model.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_constants.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

/// Repository for managing user profile data in the database
/// Handles all CRUD operations for the users table
class UserProfileRepository {
  const UserProfileRepository();

  /// Fetches user profile from the database
  Future<User?> getUserProfile(String userId, {UserApp? userApp}) async {
    try {
      final data = await SupabaseService.selectSingle(
        AuthConstants.usersTable,
        filters: {'id': userId},
      );

      if (data != null) {
        return User.fromJson(data, userApp: userApp);
      }
      return null;
    } catch (e) {
      log('Failed to fetch user profile: $e',
          name: AuthConstants.loggerName, error: e);
      return null;
    }
  }

  /// Fetches raw user profile data from the database
  Future<Map<String, dynamic>?> getUserProfileData(String userId) async {
    try {
      return await SupabaseService.selectSingle(
        AuthConstants.usersTable,
        filters: {'id': userId},
      );
    } catch (e) {
      log('Failed to fetch user profile data: $e',
          name: AuthConstants.loggerName, error: e);
      return null;
    }
  }

  /// Creates a new user record in the database
  Future<void> createUserProfile({
    required String userId,
    required String email,
    String? fullName,
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': userId,
      'email': email,
      'full_name': fullName ?? email.split('@')[0],
      'is_active': true,
      'metadata': {},
      'created_at': now,
      'updated_at': now,
    };

    await SupabaseService.insert(AuthConstants.usersTable, data);
    log('User profile created successfully', name: AuthConstants.loggerName);
  }

  /// Updates user email in the database
  Future<void> updateUserEmail(String userId, String email) async {
    final data = {
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SupabaseService.update(
      AuthConstants.usersTable,
      data,
      filters: {'id': userId},
    );
    log('User email updated successfully', name: AuthConstants.loggerName);
  }

  /// Deletes user profile from the database
  Future<void> deleteUserProfile(String userId) async {
    await SupabaseService.delete(
      AuthConstants.usersTable,
      filters: {'id': userId},
    );
    log('User profile deleted successfully', name: AuthConstants.loggerName);
  }

  /// Checks if a user profile exists
  Future<bool> userProfileExists(String userId) async {
    final data = await getUserProfileData(userId);
    return data != null;
  }
}
