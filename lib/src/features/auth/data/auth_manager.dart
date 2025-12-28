// Authentication Manager - Base interface for auth implementations
//
// This abstract class and mixins define the contract for authentication systems.
// Implement this with concrete classes for Firebase, Supabase, or local auth.
//
// Usage:
// 1. Create a concrete class extending AuthManager
// 2. Mix in the required authentication provider mixins
// 3. Implement all abstract methods with your auth provider logic

import 'package:dartz/dartz.dart';
import 'package:park_my_whip_residents/src/core/models/user_model.dart';
import 'package:park_my_whip_residents/src/core/networking/custom_exceptions.dart';

/// Signup eligibility status for cross-app user detection
enum SignupEligibilityStatus {
  /// User doesn't exist - can proceed with normal signup
  newUser,

  /// User exists in another app - should redirect to login
  existingUser,
}

/// Result of signup eligibility check
class SignupEligibilityResult {
  final SignupEligibilityStatus status;
  final String? message;

  const SignupEligibilityResult({
    required this.status,
    this.message,
  });

  bool get isNewUser => status == SignupEligibilityStatus.newUser;
  bool get isExistingUser => status == SignupEligibilityStatus.existingUser;
}

// Core authentication operations that all auth implementations must provide
abstract class AuthManager {
  Future<Either<AppException, Unit>> signOut();
  Future<Either<AppException, Unit>> deleteUser();
  Future<Either<AppException, Unit>> updateEmail({required String email});
  Future<Either<AppException, Unit>> resetPassword({required String email});
  Future<Either<AppException, Unit>> updatePassword(
      {required String newPassword});
}

// Email/password authentication mixin
mixin EmailSignInManager on AuthManager {
  Future<Either<AppException, User>> signInWithEmail(
    String email,
    String password,
  );

  Future<Either<AppException, User>> createAccountWithEmail(
    String email,
    String password,
  );

  Future<Either<AppException, Unit>> resendVerificationEmail(
      {required String email});

  /// Verify OTP code sent to email during signup
  Future<Either<AppException, User>> verifyOtpWithEmail({
    required String email,
    required String otpCode,
  });

  /// Check if user can sign up or if they should be redirected to login
  /// Used during signup flow to handle cross-app users
  Future<Either<AppException, SignupEligibilityResult>> checkSignupEligibility(
      String email);
}

// Anonymous authentication for guest users
mixin AnonymousSignInManager on AuthManager {
  Future<Either<AppException, User>> signInAnonymously();
}

// Apple Sign-In authentication (iOS/web)
mixin AppleSignInManager on AuthManager {
  Future<Either<AppException, User>> signInWithApple();
}

// Google Sign-In authentication (all platforms)
mixin GoogleSignInManager on AuthManager {
  Future<Either<AppException, User>> signInWithGoogle();
}

// JWT token authentication for custom backends
mixin JwtSignInManager on AuthManager {
  Future<Either<AppException, User>> signInWithJwtToken(String jwtToken);
}

// Phone number authentication with SMS verification
mixin PhoneSignInManager on AuthManager {
  Future<Either<AppException, Unit>> beginPhoneAuth({
    required String phoneNumber,
    required void Function() onCodeSent,
  });

  Future<Either<AppException, User>> verifySmsCode({required String smsCode});
}

// Facebook Sign-In authentication
mixin FacebookSignInManager on AuthManager {
  Future<Either<AppException, User>> signInWithFacebook();
}

// Microsoft Sign-In authentication (Azure AD)
mixin MicrosoftSignInManager on AuthManager {
  Future<Either<AppException, User>> signInWithMicrosoft(
    List<String> scopes,
    String tenantId,
  );
}

// GitHub Sign-In authentication (OAuth)
mixin GithubSignInManager on AuthManager {
  Future<Either<AppException, User>> signInWithGithub();
}
