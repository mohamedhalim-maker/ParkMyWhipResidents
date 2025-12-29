class RoutesName {
  static const initial = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';
  static const setPassword = '/set-password';
  static const enterOtpCode = '/enter-otp-code';
  static const dashboard = '/dashboard';

  // Auth routes - forgot password flow
  static const forgotPassword = '/forgot-password';
  static const resetLinkSent = '/reset-link-sent';
  static const resetLinkError = '/reset-link-error';
  static const resetPassword = '/reset-password';
  static const passwordResetSuccess = '/password-reset-success';

  // Parking routes
  static const parkingSpot = '/parking-spot';

  // Vehicle routes
  static const myVehicles = '/my-vehicles';
  static const addVehicle = '/add-vehicle';

  // Guest pass routes
  static const guestPasses = '/guest-passes';
  static const createGuestPass = '/create-guest-pass';

  // Violation routes
  static const violations = '/violations';
  static const violationDetails = '/violation-details';

  // Onboarding routes
  static const onboardingStep1 = '/onboarding-step-1';
  static const onboardingStep2 = '/onboarding-step-2';

  // Resident flow routes
  static const onboardingResidentStep1 = '/onboarding-resident-step-1';
  static const onboardingResidentStep2 = '/onboarding-resident-step-2';
  static const onboardingResidentStep3 = '/onboarding-resident-step-3';
  static const onboardingResidentStep4 = '/onboarding-resident-step-4';
  static const onboardingResidentStep5 = '/onboarding-resident-step-5';
  static const onboardingResidentStep6 = '/onboarding-resident-step-6';
  static const onboardingResidentStep7 = '/onboarding-resident-step-7';
}
