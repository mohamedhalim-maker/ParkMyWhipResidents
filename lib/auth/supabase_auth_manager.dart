import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/auth/auth_manager.dart';
import 'package:park_my_whip_residents/src/core/constants/app_config.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/core/models/user_app_model.dart';
import 'package:park_my_whip_residents/src/core/models/user_model.dart';
import 'package:park_my_whip_residents/src/core/networking/network_exceptions.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  final SharedPrefHelper _sharedPrefHelper;

  SupabaseAuthManager(this._sharedPrefHelper);

  @override
  Future<User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        log('Sign in failed: No user returned', name: 'SupabaseAuthManager');
        throw Exception('Login failed. Please try again.');
      }

      log('Sign in successful for: $email', name: 'SupabaseAuthManager');

      // Check if user is registered for this app
      final userApp = await _getUserAppRegistration(response.user!.id);
      if (userApp == null) {
        log('User not registered for app: ${AppConfig.appId}',
            name: 'SupabaseAuthManager');
        // Sign out the user since they're not registered for this app
        await SupabaseConfig.auth.signOut();
        throw Exception(
            'Your account is not registered for this app. Please sign up first.');
      }

      // Check if user is active in this app
      if (!userApp.isActive) {
        log('User is deactivated for app: ${AppConfig.appId}',
            name: 'SupabaseAuthManager');
        await SupabaseConfig.auth.signOut();
        throw Exception(
            'Your account has been deactivated for this app. Please contact support.');
      }

      // Fetch user profile from database with app registration
      final user = await _getUserProfile(response.user!.id, userApp: userApp);
      if (user != null) {
        await _cacheUser(user);
        return user;
      }

      // If user doesn't exist in database, create it and register for app
      log('User profile not found, creating new record',
          name: 'SupabaseAuthManager');
      await _createUserRecord(
        response.user!.id,
        response.user!.email ?? email,
      );

      // Fetch the newly created user with app registration
      final newUser = await _getUserProfile(response.user!.id, userApp: userApp);
      if (newUser != null) {
        await _cacheUser(newUser);
        return newUser;
      }

      // Fallback: return basic user from auth response
      return _userFromAuthUser(response.user!, userApp: userApp);
    } on sb.AuthException catch (e) {
      log('Auth error during sign in: ${e.message}',
          name: 'SupabaseAuthManager');
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Error during sign in: $e', name: 'SupabaseAuthManager');
      if (e is Exception) rethrow;
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  @override
  Future<User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      debugPrint('🔵 [SIGNUP] Creating account for email');

      // Step 1: Create account in Supabase (without email confirmation)
      final signUpResponse = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': email.split('@')[0]},
        emailRedirectTo: null, // Disable automatic email sending
      );

      debugPrint(
          '🔵 [SIGNUP] SignUp response: user=${signUpResponse.user?.id}, session=${signUpResponse.session?.accessToken != null}');

      if (signUpResponse.user == null) {
        debugPrint('🔴 [SIGNUP ERROR] No user returned from Supabase');
        throw Exception(
            'Account creation failed. No user returned from Supabase.');
      }

      debugPrint(
          '✅ [SIGNUP] Account created successfully. User ID: ${signUpResponse.user!.id}');

      // Step 2: Check if user already exists (for existing users signing up for new app)
      final existingUser = await _getUserProfileData(signUpResponse.user!.id);
      
      if (existingUser == null) {
        // Step 2a: Create user profile in database for new users
        try {
          debugPrint('🔵 [SIGNUP] Creating user profile in database...');
          await SupabaseConfig.client.from('users').insert({
            'id': signUpResponse.user!.id,
            'email': email,
            'full_name': email.split('@')[0],
            'is_active': true,
            'metadata': {},
          });
          debugPrint('✅ [SIGNUP] User profile created in database');
        } catch (dbError) {
          debugPrint('🔴 [SIGNUP ERROR] Database insert error: $dbError');
          if (dbError is PostgrestException) {
            debugPrint(
                '🔴 [SIGNUP ERROR] Postgrest error - Code: ${dbError.code}, Message: ${dbError.message}');
            // If RLS policy error, show helpful message
            if (dbError.code == '42501' ||
                dbError.message?.contains('policy') == true) {
              throw Exception(
                  'Database permission error. Please check your Supabase RLS policies for the users table.');
            }
          }
          throw Exception('Failed to create user profile: $dbError');
        }
      } else {
        debugPrint('🔵 [SIGNUP] User already exists, registering for new app');
      }

      // Step 3: Register user for this app in user_apps table
      UserApp? userApp;
      try {
        debugPrint('🔵 [SIGNUP] Registering user for app: ${AppConfig.appId}');
        userApp = await _registerUserForApp(signUpResponse.user!.id);
        debugPrint('✅ [SIGNUP] User registered for app successfully');
      } catch (appError) {
        debugPrint('🔴 [SIGNUP ERROR] App registration error: $appError');
        if (appError is PostgrestException) {
          // Check if user is already registered for this app
          if (appError.code == '23505') {
            debugPrint('⚠️ [SIGNUP] User already registered for this app');
            userApp = await _getUserAppRegistration(signUpResponse.user!.id);
          } else {
            throw Exception('Failed to register for app: $appError');
          }
        } else {
          throw Exception('Failed to register for app: $appError');
        }
      }

      // Step 4: Send verification email with deep link
      try {
        debugPrint('🔵 [SIGNUP] Sending verification email...');
        await SupabaseConfig.auth.signInWithOtp(
          email: email,
          emailRedirectTo: '${AppConfig.deepLinkScheme}://verify-email',
        );
        debugPrint('✅ [SIGNUP] Verification email sent successfully');
      } catch (emailError) {
        debugPrint(
            '⚠️ [SIGNUP WARNING] Failed to send verification email: $emailError');
        // Don't fail the signup if email sending fails
        // User can resend the email later
      }

      // Return basic user from auth response with app registration
      return _userFromAuthUser(signUpResponse.user!, userApp: userApp);
    } on sb.AuthException catch (e) {
      debugPrint(
          '🔴 [SIGNUP ERROR] Auth error - Status: ${e.statusCode}, Message: ${e.message}');
      rethrow; // Let NetworkExceptions handle it
    } on PostgrestException catch (e) {
      debugPrint(
          '🔴 [SIGNUP ERROR] Database error - Code: ${e.code}, Message: ${e.message}');
      rethrow; // Let NetworkExceptions handle it
    } catch (e) {
      debugPrint('🔴 [SIGNUP ERROR] Unexpected error: $e');
      rethrow; // Let NetworkExceptions handle it
    }
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    try {
      debugPrint('🔵 [RESEND] Resending verification email to: $email');
      // Use signInWithOtp to send verification link
      await SupabaseConfig.auth.signInWithOtp(
        email: email,
        emailRedirectTo: '${AppConfig.deepLinkScheme}://verify-email',
      );
      debugPrint('✅ [RESEND] Verification email resent successfully');
    } on sb.AuthException catch (e) {
      debugPrint('🔴 [RESEND ERROR] Auth error: ${e.message}');
      rethrow; // Let NetworkExceptions handle it
    } catch (e) {
      debugPrint('🔴 [RESEND ERROR] Unexpected error: $e');
      rethrow; // Let NetworkExceptions handle it
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
      await _clearUserCache();
      log('Sign out successful', name: 'SupabaseAuthManager');
    } catch (e) {
      log('Error during sign out: $e', name: 'SupabaseAuthManager');
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      // Delete user's app registration from user_apps
      await SupabaseService.delete('user_apps', filters: {
        'user_id': user.id,
        'app_id': AppConfig.appId,
      });

      // Check if user has any other app registrations
      final otherApps = await SupabaseConfig.client
          .from('user_apps')
          .select('id')
          .eq('user_id', user.id);

      // Only delete user record and auth if no other apps
      if (otherApps.isEmpty) {
        // Delete user record from database
        await SupabaseService.delete('users', filters: {'id': user.id});

        // Delete auth user
        await SupabaseConfig.client.rpc('delete_user');
      }

      await _clearUserCache();

      log('User deleted successfully', name: 'SupabaseAuthManager');
    } catch (e) {
      log('Error deleting user: $e', name: 'SupabaseAuthManager');
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  @override
  Future<void> updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.updateUser(sb.UserAttributes(email: email));

      // Update email in users table
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId != null) {
        await SupabaseService.update(
          'users',
          {'email': email, 'updated_at': DateTime.now().toIso8601String()},
          filters: {'id': userId},
        );
      }

      log('Email updated successfully', name: 'SupabaseAuthManager');
    } on sb.AuthException catch (e) {
      log('Auth error updating email: ${e.message}',
          name: 'SupabaseAuthManager');
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Error updating email: $e', name: 'SupabaseAuthManager');
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      log('🔵 [RESET PASSWORD] Request for: $email',
          name: 'SupabaseAuthManager', level: 800);

      // Send password reset email
      // Supabase will handle checking if the email exists
      await SupabaseConfig.auth.resetPasswordForEmail(
        email,
        redirectTo: '${AppConfig.deepLinkScheme}://reset-password',
      );

      log('✅ [RESET PASSWORD] Email sent successfully to: $email',
          name: 'SupabaseAuthManager', level: 1000);
    } on sb.AuthException catch (e) {
      log('🔴 [RESET PASSWORD ERROR] Auth error - Status: ${e.statusCode}, Message: ${e.message}',
          name: 'SupabaseAuthManager', level: 900);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('🔴 [RESET PASSWORD ERROR] Unexpected error: $e',
          name: 'SupabaseAuthManager', level: 900);
      if (e is Exception) rethrow;
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      // Update the user's password
      await SupabaseConfig.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );

      log('Password updated successfully', name: 'SupabaseAuthManager');
    } on sb.AuthException catch (e) {
      log('Auth error updating password: ${e.message}',
          name: 'SupabaseAuthManager');
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Error updating password: $e', name: 'SupabaseAuthManager');
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  // Private helper methods

  /// Fetches user profile from the database with optional app registration
  Future<User?> _getUserProfile(String userId, {UserApp? userApp}) async {
    try {
      final data = await SupabaseService.selectSingle(
        'users',
        filters: {'id': userId},
      );

      if (data != null) {
        return User.fromJson(data, userApp: userApp);
      }
      return null;
    } catch (e) {
      log('Could not fetch user profile: $e', name: 'SupabaseAuthManager');
      return null;
    }
  }

  /// Fetches raw user profile data from the database (without User model)
  Future<Map<String, dynamic>?> _getUserProfileData(String userId) async {
    try {
      return await SupabaseService.selectSingle(
        'users',
        filters: {'id': userId},
      );
    } catch (e) {
      log('Could not fetch user profile data: $e', name: 'SupabaseAuthManager');
      return null;
    }
  }

  /// Fetches user's app registration from user_apps table
  Future<UserApp?> _getUserAppRegistration(String userId) async {
    try {
      final data = await SupabaseService.selectSingle(
        'user_apps',
        filters: {
          'user_id': userId,
          'app_id': AppConfig.appId,
        },
      );

      if (data != null) {
        return UserApp.fromJson(data);
      }
      return null;
    } catch (e) {
      log('Could not fetch user app registration: $e',
          name: 'SupabaseAuthManager');
      return null;
    }
  }

  /// Registers a user for the current app
  Future<UserApp> _registerUserForApp(String userId) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'user_id': userId,
      'app_id': AppConfig.appId,
      'role': 'user',
      'is_active': true,
      'app_specific_data': {},
      'created_at': now,
      'updated_at': now,
    };

    final result = await SupabaseConfig.client
        .from('user_apps')
        .insert(data)
        .select()
        .single();

    return UserApp.fromJson(result);
  }

  /// Creates a new user record in the database
  Future<void> _createUserRecord(String userId, String email) async {
    try {
      await SupabaseService.insert('users', {
        'id': userId,
        'email': email,
        'full_name': email.split('@')[0], // Default to email username
        'is_active': true,
        'metadata': {},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      log('User record created successfully', name: 'SupabaseAuthManager');
    } catch (e) {
      log('Error creating user record: $e', name: 'SupabaseAuthManager');
      rethrow;
    }
  }

  /// Creates a basic User object from Supabase auth user
  User _userFromAuthUser(sb.User authUser, {UserApp? userApp}) => User(
        id: authUser.id,
        email: authUser.email ?? '',
        fullName: authUser.email?.split('@')[0] ?? 'User',
        phone: authUser.phone,
        avatarUrl: null,
        isActive: true,
        metadata: {},
        createdAt: DateTime.parse(authUser.createdAt),
        updatedAt: DateTime.now(),
        userApp: userApp,
      );

  /// Caches user data in local storage
  Future<void> _cacheUser(User user) async {
    try {
      await _sharedPrefHelper.saveObject('user_profile', user.toJson());
      await _sharedPrefHelper.saveString('user_id', user.id);
      log('User cached successfully', name: 'SupabaseAuthManager');
    } catch (e) {
      log('Error caching user: $e', name: 'SupabaseAuthManager');
    }
  }

  /// Clears user cache from local storage
  Future<void> _clearUserCache() async {
    try {
      await _sharedPrefHelper.remove('user_profile');
      await _sharedPrefHelper.remove('user_id');
      log('User cache cleared', name: 'SupabaseAuthManager');
    } catch (e) {
      log('Error clearing cache: $e', name: 'SupabaseAuthManager');
    }
  }
}
