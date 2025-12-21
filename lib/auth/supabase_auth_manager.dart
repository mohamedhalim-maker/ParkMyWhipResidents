import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/auth/auth_manager.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/core/models/user_model.dart';
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

      // Fetch user profile from database
      final user = await _getUserProfile(response.user!.id);
      if (user != null) {
        await _cacheUser(user);
        return user;
      }

      // If user doesn't exist in database, create it
      log('User profile not found, creating new record',
          name: 'SupabaseAuthManager');
      await _createUserRecord(
        response.user!.id,
        response.user!.email ?? email,
      );

      // Fetch the newly created user
      final newUser = await _getUserProfile(response.user!.id);
      if (newUser != null) {
        await _cacheUser(newUser);
        return newUser;
      }

      // Fallback: return basic user from auth response
      return _userFromAuthUser(response.user!);
    } on sb.AuthException catch (e) {
      log('Auth error during sign in: ${e.message}',
          name: 'SupabaseAuthManager');
      throw Exception(_handleAuthError(e));
    } catch (e) {
      log('Error during sign in: $e', name: 'SupabaseAuthManager');
      throw Exception('An unexpected error occurred. Please try again.');
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

      // Step 2: Create user profile in database
      try {
        debugPrint('🔵 [SIGNUP] Creating user profile in database...');
        await SupabaseConfig.client.from('users').insert({
          'id': signUpResponse.user!.id,
          'email': email,
          'full_name': email.split('@')[0],
          'role': 'user',
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

      // Step 3: Send verification email with deep link
      try {
        debugPrint('🔵 [SIGNUP] Sending verification email...');
        await SupabaseConfig.auth.signInWithOtp(
          email: email,
          emailRedirectTo: 'parkmywhip-resident://verify-email',
        );
        debugPrint('✅ [SIGNUP] Verification email sent successfully');
      } catch (emailError) {
        debugPrint(
            '⚠️ [SIGNUP WARNING] Failed to send verification email: $emailError');
        // Don't fail the signup if email sending fails
        // User can resend the email later
      }

      // Return basic user from auth response
      return _userFromAuthUser(signUpResponse.user!);
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
        emailRedirectTo: 'parkmywhip-resident://verify-email',
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

      // Delete user record from database
      await SupabaseService.delete('users', filters: {'id': user.id});

      // Delete auth user
      await SupabaseConfig.client.rpc('delete_user');
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
      throw Exception(_handleAuthError(e));
    } catch (e) {
      log('Error updating email: $e', name: 'SupabaseAuthManager');
      throw Exception('Failed to update email. Please try again.');
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
        redirectTo: 'parkmywhip-resident://reset-password',
      );

      log('✅ [RESET PASSWORD] Email sent successfully to: $email',
          name: 'SupabaseAuthManager', level: 1000);
    } on sb.AuthException catch (e) {
      log('🔴 [RESET PASSWORD ERROR] Auth error - Status: ${e.statusCode}, Message: ${e.message}',
          name: 'SupabaseAuthManager', level: 900);

      // Handle rate limiting explicitly - check both message and status code
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('too many') ||
          errorMessage.contains('rate limit') ||
          errorMessage.contains('email rate limit exceeded') ||
          e.statusCode == '429') {
        throw Exception(
            'Too many password reset attempts. Please wait a few minutes before trying again.');
      }

      // Handle other auth errors
      throw Exception(_handleAuthError(e));
    } catch (e) {
      log('🔴 [RESET PASSWORD ERROR] Unexpected error: $e',
          name: 'SupabaseAuthManager', level: 900);

      // Re-throw custom exceptions without wrapping
      final errorString = e.toString();
      if (errorString.contains('No account found') ||
          errorString.contains('Too many password reset attempts')) {
        rethrow;
      }

      throw Exception('Failed to send password reset email. Please try again.');
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
      throw Exception(_handleAuthError(e));
    } catch (e) {
      log('Error updating password: $e', name: 'SupabaseAuthManager');
      throw Exception('Failed to update password. Please try again.');
    }
  }

  // Private helper methods

  /// Fetches user profile from the database
  Future<User?> _getUserProfile(String userId) async {
    try {
      final data = await SupabaseService.selectSingle(
        'users',
        filters: {'id': userId},
      );

      if (data != null) {
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      log('Could not fetch user profile: $e', name: 'SupabaseAuthManager');
      return null;
    }
  }

  /// Creates a new user record in the database
  Future<void> _createUserRecord(String userId, String email) async {
    try {
      await SupabaseService.insert('users', {
        'id': userId,
        'email': email,
        'full_name': email.split('@')[0], // Default to email username
        'role': 'user',
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
  User _userFromAuthUser(sb.User authUser) => User(
        id: authUser.id,
        email: authUser.email ?? '',
        fullName: authUser.email?.split('@')[0] ?? 'User',
        phone: authUser.phone,
        avatarUrl: null,
        role: 'user',
        isActive: true,
        metadata: {},
        createdAt: DateTime.parse(authUser.createdAt),
        updatedAt: DateTime.now(),
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

  /// Converts Supabase auth errors to user-friendly messages
  String _handleAuthError(sb.AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }

    if (message.contains('email not confirmed') ||
        message.contains('email not verified')) {
      return 'Please verify your email address before logging in. Check your inbox for the verification link.';
    }

    if (message.contains('user not found')) {
      return 'No account found with this email.';
    }

    if (message.contains('email already registered') ||
        message.contains('user already registered')) {
      return 'This email is already registered. Try logging in instead.';
    }

    if (message.contains('weak password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
    }

    return error.message.isNotEmpty
        ? error.message
        : 'Authentication failed. Please try again.';
  }
}
