class RoutesName {
  static const initial = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';
  static const setPassword = '/set-password';
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
}
