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

  // Claim Permit flow routes
  static const claimPermitSetupAddress = '/claim-permit-setup-address';
  static const claimPermitAddBuildingUnit = '/claim-permit-add-building-unit';
  static const claimPermitSelectPermitPlan = '/claim-permit-select-permit-plan';
  static const claimPermitAddVehicleInfo = '/claim-permit-add-vehicle-info';
  static const claimPermitUploadLicense = '/claim-permit-upload-license';
  static const claimPermitUploadRegistration =
      '/claim-permit-upload-registration';
  static const claimPermitUploadInsurance = '/claim-permit-upload-insurance';
  static const claimPermitConfirmDetails = '/claim-permit-confirm-details';
}
