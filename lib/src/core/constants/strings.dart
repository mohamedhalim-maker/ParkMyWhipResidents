class AppStrings {
  static const String appName = 'ParkMyWhip Resident';
}

class AuthStrings {
 // Register
  static const String welcomeTitle = 'Welcome to ParkMyWhip!';
  static const String createAccount = "Let's create your account";
  static const String nameLabel = 'Your first and last name';
  static const String nameHint = 'Example: John Doe';
  static const String emailLabel = 'Your email';
  static const String emailHint = 'Wade@gmail.com';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signIn = 'Sign in';
  static const String continueText = 'Continue';
  static const String otpTitle = 'Enter the OTP code';
  static const String otpSubtitle =
      "We've just emailed a code to your inbox. Please enter it below.";
  static const String createPassword = 'Create password';
  static const String passwordLabel = 'Create your password';
  static const String confirmPasswordLabel = 'Confirm password';

  // Login
  static const String welcomeBack = 'Welcome Back!';
  static const String loginToApp = 'Log in to ParkMyWhip';
  static const String emailLabelShort = 'Email';
  static const String emailHintExample = 'Wade@gmail.com';
  static const String passwordLabelShort = 'Password';
  static const String forgotPassword = 'Forgot password?';
  static const String dontHaveAccount = 'Do not have an account? ';
  static const String signUp = 'Signup';
  static const String signup = 'Signup';
  static const String login = 'Login';

  // Field labels and hints
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String enterFirstName = 'Enter your first name';
  static const String enterLastName = 'Enter your last name';
  static const String enterEmail = 'Enter your email';
  static const String enterPassword = 'Enter your password';
  static const String enterConfirmPassword = 'Confirm your password';

  // Forgot Password
  static const String confirmYourEmail = 'Confirm your email';
  static const String resetPasswordSubtitle = "We'll email you a link to reset your password";
  static const String resetLinkSent = 'Reset Link Sent';
  static const String resetLinkSentSubtitle = "You should receive an email in your inbox shortly to reset your account's password";
  static const String goToLogin = 'Go to login';
  static const String resend = 'Resend';
  static const String resendIn = 'Resend in';
  
  // Reset Password
  static const String resetYourPassword = 'Reset your password';
  static const String passwordMinCharacters = 'Be a minimum of 12 characters';
  static const String passwordUppercase = 'Include at least one uppercase letter (A-Z)';
  static const String passwordLowercase = 'Include at least one lowercase (a-z)';
  static const String passwordNumber = 'Include at least one number (0-9)';
  
  // Reset Link Error
  static const String linkExpired = 'Link Expired';
  static const String linkExpiredMessage = 'This password reset link is invalid or has expired.';
  static const String linkExpiredInstruction = 'Please request a new password reset link from the login page.';
  static const String goToLoginButton = 'Go to Login';
  
  // Password Reset Success
  static const String passwordResetSuccess = 'Password Reset Successfully!';
  static const String passwordResetSuccessMessage = 'Your password has been changed successfully. You can now log in with your new password.';
}


class SharedPrefStrings {
  static const String userId = 'user_id';
  static const String userProfile = 'user_profile';
  static const String authToken = 'auth_token';
  static const String isLoggedIn = 'is_logged_in';
}

class ErrorStrings {
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPassword = 'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String requiredField = 'This field is required';
  static const String invalidPhone = 'Please enter a valid phone number';
}
