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

  /// Fetches user profile data by email from the database
  /// Uses RPC function to bypass RLS (for password reset validation)
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    try {
      final result = await SupabaseConfig.client
          .rpc('get_user_by_email', params: {'user_email': email});

      if (result == null) return null;

      // RPC returns jsonb, convert to Map
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      log('Failed to fetch user profile by email: $e',
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

  /// Checks if a user with the given email exists and is registered for the specified app
  /// Uses RPC function to bypass RLS
  ///
  /// Returns:
  /// - `null` if user doesn't exist
  /// - `{'user': {...}, 'user_app': null}` if user exists but NOT registered for this app
  /// - `{'user': {...}, 'user_app': {...}}` if user is registered for this app ✅
  Future<Map<String, dynamic>?> checkUserAppAccess({
    required String email,
    required String appId,
  }) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'get_user_by_email_with_app_check',
        params: {
          'user_email': email,
          'p_app_id': appId,
        },
      );

      if (result == null) return null;
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      log('Failed to check user app access: $e',
          name: AuthConstants.loggerName, error: e);
      rethrow; // Let the caller handle via NetworkExceptions
    }
  }

  /// Creates user profile and app registration using RPC function
  /// Used during signup flow after OTP verification
  ///
  /// Returns:
  /// - `{'user': {...}, 'user_app': {...}}` with newly created records
  Future<Map<String, dynamic>?> createUserProfileWithApp({
    required String userId,
    required String email,
    required String appId,
  }) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'create_user_profile',
        params: {
          'p_user_id': userId,
          'p_email': email,
          'p_app_id': appId,
        },
      );

      if (result == null) return null;
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      log('Failed to create user profile with app: $e',
          name: AuthConstants.loggerName, error: e);
      rethrow; // Let the caller handle via NetworkExceptions
    }
  }

  /// Deletes user from Supabase Auth using RPC function
  /// Should only be called when user has no other app registrations
  Future<void> deleteAuthUser() async {
    try {
      await SupabaseConfig.client.rpc('delete_user');
      log('Auth user deleted successfully', name: AuthConstants.loggerName);
    } catch (e) {
      log('Failed to delete auth user: $e',
          name: AuthConstants.loggerName, error: e);
      rethrow; // Let the caller handle via NetworkExceptions
    }
  }

  /// Checks if user exists and grants app access if they exist but aren't registered
  /// Used during signup flow to handle cross-app users
  ///
  /// Returns:
  /// - `{'user': null, 'user_app': null}` if user doesn't exist (new user)
  /// - `{'user': {...}, 'user_app': {...}}` if user exists and was granted access
  Future<Map<String, dynamic>?> checkUserAndGrantAppAccess({
    required String email,
    required String appId,
  }) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'check_user_and_grant_app_access',
        params: {
          'user_email': email,
          'p_app_id': appId,
        },
      );

      if (result == null) return null;
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      log('Failed to check user and grant app access: $e',
          name: AuthConstants.loggerName, error: e);
      rethrow; // Let the caller handle via NetworkExceptions
    }
  }
}
