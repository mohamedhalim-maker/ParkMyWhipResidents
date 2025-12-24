// Authentication Manager - Base interface for auth implementations
//
// This abstract class and mixins define the contract for authentication systems.
// Implement this with concrete classes for Firebase, Supabase, or local auth.
//
// Usage:
// 1. Create a concrete class extending AuthManager
// 2. Mix in the required authentication provider mixins
// 3. Implement all abstract methods with your auth provider logic

import 'package:park_my_whip_residents/src/core/models/user_model.dart';

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
  Future<void> signOut();
  Future<void> deleteUser();
  Future<void> updateEmail({required String email});
  Future<void> resetPassword({required String email});
  Future<void> updatePassword({required String newPassword});
  Future<void> sendEmailVerification({required User user}) async =>
      user.sendEmailVerification();
  Future<void> refreshUser({required User user}) async => user.refreshUser();
}

// Email/password authentication mixin
mixin EmailSignInManager on AuthManager {
  Future<User?> signInWithEmail(
    String email,
    String password,
  );

  Future<User?> createAccountWithEmail(
    String email,
    String password,
  );

  Future<void> resendVerificationEmail({required String email});

  /// Verify OTP code sent to email during signup
  Future<User?> verifyOtpWithEmail({
    required String email,
    required String otpCode,
  });

  /// Check if user can sign up or if they should be redirected to login
  /// Used during signup flow to handle cross-app users
  Future<SignupEligibilityResult> checkSignupEligibility(String email);
}

// Anonymous authentication for guest users
mixin AnonymousSignInManager on AuthManager {
  Future<User?> signInAnonymously();
}

// Apple Sign-In authentication (iOS/web)
mixin AppleSignInManager on AuthManager {
  Future<User?> signInWithApple();
}

// Google Sign-In authentication (all platforms)
mixin GoogleSignInManager on AuthManager {
  Future<User?> signInWithGoogle();
}

// JWT token authentication for custom backends
mixin JwtSignInManager on AuthManager {
  Future<User?> signInWithJwtToken(String jwtToken);
}

// Phone number authentication with SMS verification
mixin PhoneSignInManager on AuthManager {
  Future<void> beginPhoneAuth({
    required String phoneNumber,
    required void Function() onCodeSent,
  });

  Future<User?> verifySmsCode({required String smsCode});
}

// Facebook Sign-In authentication
mixin FacebookSignInManager on AuthManager {
  Future<User?> signInWithFacebook();
}

// Microsoft Sign-In authentication (Azure AD)
mixin MicrosoftSignInManager on AuthManager {
  Future<User?> signInWithMicrosoft(
    List<String> scopes,
    String tenantId,
  );
}

// GitHub Sign-In authentication (OAuth)
mixin GithubSignInManager on AuthManager {
  Future<User?> signInWithGithub();
}
