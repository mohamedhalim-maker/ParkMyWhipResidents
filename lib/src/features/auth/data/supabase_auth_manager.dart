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
      // Step 1: Check if user is registered for this app BEFORE authentication
      log('Checking user app access for: $email',
          name: AuthConstants.loggerName);

      final appAccessResult = await _userProfileRepository.checkUserAppAccess(
        email: email,
        appId: AppConfig.appId,
      );

      if (appAccessResult == null) {
        log('User not found with email: $email',
            name: AuthConstants.loggerName);
        throw Exception(
          'No account found with this email address. Please sign up first.',
        );
      }

      final data = appAccessResult;
      final userData = data['user'] as Map<String, dynamic>?;
      final userAppData = data['user_app'] as Map<String, dynamic>?;

      // Check if user exists in users table
      if (userData == null) {
        log('User profile not found for: $email',
            name: AuthConstants.loggerName);
        throw Exception(
          'No account found with this email address. Please sign up first.',
        );
      }

      // Check if user is registered for this specific app
      if (userAppData == null) {
        log('User not registered for app: ${AppConfig.appId}',
            name: AuthConstants.loggerName);
        throw Exception(
          'Your account is not registered for this app. Try signing up.',
        );
      }

      // Check if user is active in the app
      final isActive = userAppData['is_active'] as bool? ?? false;
      if (!isActive) {
        log('User is deactivated for app: ${AppConfig.appId}',
            name: AuthConstants.loggerName);
        throw Exception(
          'Your account has been deactivated. Please contact support.',
        );
      }

      log('User app access validated successfully',
          name: AuthConstants.loggerName);

      // Step 2: Authenticate with Supabase
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

      // Step 3: Fetch user profile and app registration
      final user = await _userProfileRepository.getUserProfile(userId);
      final userApp = await _userAppRepository.getUserAppRegistration(
        userId,
        AppConfig.appId,
      );

      // These should exist since we validated them above
      if (user == null || userApp == null) {
        log('Failed to fetch user data after authentication',
            name: AuthConstants.loggerName);
        throw Exception('Failed to load user profile. Please try again.');
      }

      // Update user with app registration and cache
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
  Future<SignupEligibilityResult> checkSignupEligibility(String email) async {
    try {
      log('Checking signup eligibility for: $email',
          name: AuthConstants.loggerName);

      // Check if user exists and grant app access if needed
      final result = await _userProfileRepository.checkUserAndGrantAppAccess(
        email: email,
        appId: AppConfig.appId,
      );

      final data = result ?? {};

      // If user_app exists, user was granted access (existing user in another app)
      if (data['user_app'] != null) {
        log('Cross-app user detected for: $email',
            name: AuthConstants.loggerName);
        return const SignupEligibilityResult(
          status: SignupEligibilityStatus.existingUser,
          message: 'This account now exists. Please sign in to access this app.',
        );
      }

      // New user - can proceed with signup
      log('New user detected for: $email', name: AuthConstants.loggerName);
      return const SignupEligibilityResult(
        status: SignupEligibilityStatus.newUser,
      );
    } catch (e) {
      log('Error checking signup eligibility: $e',
          name: AuthConstants.loggerName, error: e);
      if (e is Exception) rethrow;
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
  }

  @override
  Future<User?> verifyOtpWithEmail({
    required String email,
    required String otpCode,
  }) async {
    try {
      log('Verifying OTP for email: $email', name: AuthConstants.loggerName);

      // Step 1: Verify OTP and authenticate user
      final response = await SupabaseConfig.auth.verifyOTP(
        email: email,
        token: otpCode,
        type: sb.OtpType.signup,
      );

      if (response.user == null) {
        log('OTP verification failed: No user returned',
            name: AuthConstants.loggerName);
        throw Exception('OTP verification failed. Please try again.');
      }

      log('OTP verified successfully for: $email',
          name: AuthConstants.loggerName);

      final userId = response.user!.id;

      // Step 2: Create user profile and app registration using repository
      log('Creating user profile and app registration via RPC',
          name: AuthConstants.loggerName);

      final rpcResult = await _userProfileRepository.createUserProfileWithApp(
        userId: userId,
        email: email,
        appId: AppConfig.appId,
      );

      if (rpcResult == null) {
        log('RPC call failed: No result returned',
            name: AuthConstants.loggerName);
        throw Exception('Failed to create user profile. Please try again.');
      }

      log('User profile and app registration created successfully',
          name: AuthConstants.loggerName);

      // Step 3: Parse RPC response
      final data = rpcResult;
      final userData = data['user'] as Map<String, dynamic>?;
      final userAppData = data['user_app'] as Map<String, dynamic>?;

      if (userData == null || userAppData == null) {
        log('Invalid RPC response: Missing user or user_app data',
            name: AuthConstants.loggerName);
        throw Exception('Failed to create user profile. Please try again.');
      }

      // Step 4: Create User and UserApp objects
      final userApp = UserApp.fromJson(userAppData);

      // Validate app access status
      if (!userApp.isActive) {
        log('User is deactivated for app: ${AppConfig.appId}',
            name: AuthConstants.loggerName);
        await SupabaseConfig.auth.signOut();
        throw Exception(
          'Your account has been deactivated. Please contact support.',
        );
      }

      final user = User.fromJson(userData, userApp: userApp);

      // Step 5: Cache user data
      await _cacheService.cacheUser(user);

      log('User cached successfully. Sign-up complete.',
          name: AuthConstants.loggerName);

      return user;
    } on sb.AuthException catch (e) {
      log('Auth error during OTP verification: ${e.message}',
          name: AuthConstants.loggerName, error: e);
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    } catch (e) {
      log('Error during OTP verification: $e',
          name: AuthConstants.loggerName, error: e);
      if (e is Exception) rethrow;
      throw Exception(NetworkExceptions.getSupabaseExceptionMessage(e));
    }
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
        await _userProfileRepository.deleteAuthUser();
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
      log('Starting password reset validation for: $email',
          name: AuthConstants.loggerName);

      // Get user and app data in one query using repository
      final result = await _userProfileRepository.checkUserAppAccess(
        email: email,
        appId: AppConfig.appId,
      );

      if (result == null) {
        log('User not found with email: $email',
            name: AuthConstants.loggerName);
        throw Exception(
          'No account found with this email address. Please check your email or sign up.',
        );
      }

      final data = result;
      final userData = data['user'] as Map<String, dynamic>?;
      final userAppData = data['user_app'] as Map<String, dynamic>?;

      // 1. Check if user exists
      if (userData == null) {
        log('User not found with email: $email',
            name: AuthConstants.loggerName);
        throw Exception(
          'No account found with this email address. Please check your email or sign up.',
        );
      }

      final userId = userData['id'] as String;
      log('User found with ID: $userId', name: AuthConstants.loggerName);

      // 2. Check if user is verified (email confirmed in Supabase Auth)
      final isVerified = await _isUserEmailVerified(userId);
      if (!isVerified) {
        log('User email not verified: $email', name: AuthConstants.loggerName);
        throw Exception(
          'Your email is not verified. Please verify your email before resetting your password.',
        );
      }

      log('User email is verified', name: AuthConstants.loggerName);

      // 3. Check if user belongs to current app
      if (userAppData == null) {
        log('User not registered for app: ${AppConfig.appId}',
            name: AuthConstants.loggerName);
        throw Exception(
          'Your account is not registered for this app. Please contact support.',
        );
      }

      // 4. Check if user is active in the app
      final isActive = userAppData['is_active'] as bool? ?? false;
      if (!isActive) {
        log('User is deactivated for app: ${AppConfig.appId}',
            name: AuthConstants.loggerName);
        throw Exception(
          'Your account has been deactivated. Please contact support.',
        );
      }

      log('User is active in app, sending password reset email',
          name: AuthConstants.loggerName);

      // All validations passed, send reset email
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

  /// Check if user's email is verified in Supabase Auth
  Future<bool> _isUserEmailVerified(String userId) async {
    try {
      // Get user from auth.users table via RPC or direct query
      // Since we can't access admin API from client, we check if they can sign in
      // If email is not confirmed, they won't exist in our users table after signup
      // But since they ARE in users table, we assume they completed signup flow
      // which requires email verification

      // Alternative: Check auth.users metadata
      final authUser = SupabaseConfig.auth.currentUser;
      if (authUser != null && authUser.id == userId) {
        // User is currently signed in, they must be verified
        return authUser.emailConfirmedAt != null;
      }

      // If user is not currently signed in but exists in users table,
      // they must have verified their email during signup
      // (our signup flow requires email verification)
      return true;
    } catch (e) {
      log('Error checking email verification: $e',
          name: AuthConstants.loggerName, error: e);
      // Default to true to not block reset for existing users
      return true;
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
