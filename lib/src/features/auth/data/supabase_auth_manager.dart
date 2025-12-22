import 'dart:developer';
import 'package:park_my_whip_residents/src/core/constants/app_config.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/core/models/user_app_model.dart';
import 'package:park_my_whip_residents/src/core/models/user_model.dart';
import 'package:park_my_whip_residents/src/core/networking/network_exceptions.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_constants.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_manager.dart';
import 'package:park_my_whip_residents/src/features/auth/data/user_app_repository.dart';
import 'package:park_my_whip_residents/src/features/auth/data/user_cache_service.dart';
import 'package:park_my_whip_residents/src/features/auth/data/user_profile_repository.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Supabase implementation of AuthManager
/// Handles authentication operations using Supabase Auth
/// Follows SOLID principles with separated repositories for data operations
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  final UserProfileRepository _userProfileRepository;
  final UserAppRepository _userAppRepository;
  final UserCacheService _cacheService;

  SupabaseAuthManager({
    required SharedPrefHelper sharedPrefHelper,
    UserProfileRepository? userProfileRepository,
    UserAppRepository? userAppRepository,
  })  : _userProfileRepository =
            userProfileRepository ?? const UserProfileRepository(),
        _userAppRepository = userAppRepository ?? const UserAppRepository(),
        _cacheService = UserCacheService(sharedPrefHelper);

  @override
  Future<User?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        log('Sign in failed: No user returned', name: AuthConstants.loggerName);
        throw Exception('Login failed. Please try again.');
      }

      log('Sign in successful for: $email', name: AuthConstants.loggerName);

      final userId = response.user!.id;

      // Ensure user profile exists (creates if missing)
      final user = await _getUserWithProfile(userId);

      // Ensure app registration exists (creates if missing)
      final userApp = await _ensureUserAppRegistration(userId);

      // Validate app access status
      if (!userApp.isActive) {
        log('User is deactivated for app: ${AppConfig.appId}',
            name: AuthConstants.loggerName);
        await SupabaseConfig.auth.signOut();
        throw Exception(
          'Your account has been deactivated. Please contact support.',
        );
      }

      // Update user with app registration and re-cache
      final userWithApp = user.copyWith(userApp: userApp);
      await _cacheService.cacheUser(userWithApp);

      return userWithApp;
    } on sb.AuthException catch (e) {
      log('Auth error during sign in: ${e.message}',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Error during sign in: $e', name: AuthConstants.loggerName, error: e);
      if (e is Exception) rethrow;
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  @override
  Future<User?> createAccountWithEmail(
    String email,
    String password,
  ) async {
    try {
      log('Creating account for: $email', name: AuthConstants.loggerName);

      // Create account in Supabase
      final signUpResponse = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': email.split('@')[0]},
        emailRedirectTo: null, // Manual email verification
      );

      if (signUpResponse.user == null) {
        log('Account creation failed: No user returned',
            name: AuthConstants.loggerName);
        throw Exception('Account creation failed. Please try again.');
      }

      final userId = signUpResponse.user!.id;
      log('Account created successfully. User ID: $userId',
          name: AuthConstants.loggerName);

      // Send verification email
      // Note: User profile and app registration will be created on first login
      // after email confirmation
      // await _sendVerificationEmail(email);

      return _userFromAuthUser(signUpResponse.user!, userApp: null);
    } on sb.AuthException catch (e) {
      log('Auth error during account creation: ${e.message}',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } on PostgrestException catch (e) {
      log('Database error during account creation: ${e.message}',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Unexpected error during account creation: $e',
          name: AuthConstants.loggerName, error: e);
      if (e is Exception) rethrow;
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    await _sendVerificationEmail(email);
  }

  @override
  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
      await _cacheService.clearCache();
      log('Sign out successful', name: AuthConstants.loggerName);
    } catch (e) {
      log('Error during sign out: $e',
          name: AuthConstants.loggerName, error: e);
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      final userId = user.id;

      // Delete user's app registration
      await _userAppRepository.deleteUserAppRegistration(
        userId,
        AppConfig.appId,
      );

      // Only delete user record and auth if no other apps
      final hasOtherApps = await _userAppRepository.hasOtherAppRegistrations(
        userId,
        AppConfig.appId,
      );

      if (!hasOtherApps) {
        await _userProfileRepository.deleteUserProfile(userId);
        await SupabaseConfig.client.rpc('delete_user');
      }

      await _cacheService.clearCache();

      log('User deleted successfully', name: AuthConstants.loggerName);
    } catch (e) {
      log('Error deleting user: $e', name: AuthConstants.loggerName, error: e);
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  @override
  Future<void> updateEmail({required String email}) async {
    try {
      await SupabaseConfig.auth.updateUser(sb.UserAttributes(email: email));

      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId != null) {
        await _userProfileRepository.updateUserEmail(userId, email);
      }

      log('Email updated successfully', name: AuthConstants.loggerName);
    } on sb.AuthException catch (e) {
      log('Auth error updating email: ${e.message}',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Error updating email: $e', name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      log('Sending password reset email to: $email',
          name: AuthConstants.loggerName);

      await SupabaseConfig.auth.resetPasswordForEmail(
        email,
        redirectTo: AuthConstants.resetPasswordRedirectUrl(
          AppConfig.deepLinkScheme,
        ),
      );

      log('Password reset email sent successfully',
          name: AuthConstants.loggerName);
    } on sb.AuthException catch (e) {
      log('Auth error during password reset: ${e.message}',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Error during password reset: $e',
          name: AuthConstants.loggerName, error: e);
      if (e is Exception) rethrow;
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await SupabaseConfig.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );

      log('Password updated successfully', name: AuthConstants.loggerName);
    } on sb.AuthException catch (e) {
      log('Auth error updating password: ${e.message}',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Error updating password: $e',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  // Private helper methods

  /// Ensures user app registration exists, creates if missing
  Future<UserApp> _ensureUserAppRegistration(String userId) async {
    // Try to get existing registration
    var userApp = await _userAppRepository.getUserAppRegistration(
      userId,
      AppConfig.appId,
    );

    // If doesn't exist, create it
    if (userApp == null) {
      log('App registration not found, creating new registration',
          name: AuthConstants.loggerName);
      userApp = await _userAppRepository.registerUserForApp(
        userId: userId,
        appId: AppConfig.appId,
      );
    }

    return userApp;
  }

  /// Gets user with profile, creating it if it doesn't exist
  Future<User> _getUserWithProfile(String userId, {UserApp? userApp}) async {
    // Try to fetch existing profile
    var user =
        await _userProfileRepository.getUserProfile(userId, userApp: userApp);

    if (user != null) {
      return user;
    }

    // Profile doesn't exist, create it
    log('User profile not found, creating new record',
        name: AuthConstants.loggerName);

    final authUser = SupabaseConfig.auth.currentUser;
    if (authUser != null) {
      await _userProfileRepository.createUserProfile(
        userId: userId,
        email: authUser.email ?? '',
      );

      // Fetch the newly created user
      user =
          await _userProfileRepository.getUserProfile(userId, userApp: userApp);
      if (user != null) {
        return user;
      }
    }

    // Fallback: return basic user from auth
    return _userFromAuthUser(
      SupabaseConfig.auth.currentUser!,
      userApp: userApp,
    );
  }

  /// Sends verification email to user
  Future<void> _sendVerificationEmail(String email) async {
    try {
      log('Sending verification email to: $email',
          name: AuthConstants.loggerName);

      await SupabaseConfig.auth.signInWithOtp(
        email: email,
        emailRedirectTo: AuthConstants.verifyEmailRedirectUrl(
          AppConfig.deepLinkScheme,
        ),
      );

      log('Verification email sent successfully',
          name: AuthConstants.loggerName);
    } on sb.AuthException catch (e) {
      log('Failed to send verification email: ${e.message}',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Unexpected error sending verification email: $e',
          name: AuthConstants.loggerName, error: e);
      if (e is Exception) rethrow;
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
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
}
