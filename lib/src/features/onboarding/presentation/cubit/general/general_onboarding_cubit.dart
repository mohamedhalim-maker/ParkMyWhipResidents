import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/onboarding/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/general/general_onboarding_state.dart';

/// Cubit managing the general onboarding flow (Steps 1-2).
///
/// Responsibilities:
/// - Manage user name input (first name, last name)
/// - Manage terms acceptance checkbox
/// - Validate personal info
/// - Manage user type selection (Resident/Visitor)
/// - Navigate between general onboarding steps
/// - Navigate to appropriate flow based on user type
///
/// This is a SINGLETON cubit (registered with registerLazySingleton)
/// so the same instance is shared across general onboarding pages.
class GeneralOnboardingCubit extends Cubit<GeneralOnboardingState> {
  // ==================== Controllers ====================
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  bool termsAccepted = false;

  GeneralOnboardingCubit() : super(const GeneralOnboardingState()) {
    // Listen to text field changes to enable/disable button
    firstNameController.addListener(_updateButtonState);
    lastNameController.addListener(_updateButtonState);
  }

  // ==================== Field Change Handlers ====================

  /// Update button enabled state based on field values
  void _updateButtonState() {
    final isValid = _isPersonalInfoValid();
    if (state.isButtonEnabled != isValid) {
      emit(state.copyWith(isButtonEnabled: isValid));
    }
  }

  /// Check if personal info fields are valid for enabling button
  bool _isPersonalInfoValid() =>
      firstNameController.text.trim().isNotEmpty &&
      lastNameController.text.trim().isNotEmpty &&
      termsAccepted;

  /// Handle first name field change (clears error)
  void onFirstNameChanged() {
    if (state.firstNameError != null) {
      emit(state.copyWith(firstNameError: () => null));
    }
  }

  /// Handle last name field change (clears error)
  void onLastNameChanged() {
    if (state.lastNameError != null) {
      emit(state.copyWith(lastNameError: () => null));
    }
  }

  /// Handle terms checkbox change
  void onTermsChanged(bool value) {
    termsAccepted = value;
    _updateButtonState();
  }

  // ==================== Validation ====================

  /// Validate personal info step (called on Continue button press)
  void onContinuePersonalInfo({required BuildContext context}) {
    final firstNameError =
        OnboardingValidators.validateName(firstNameController.text);
    final lastNameError =
        OnboardingValidators.validateName(lastNameController.text);

    // If both are valid, clear any existing errors
    if (firstNameError == null && lastNameError == null) {
      emit(state.copyWith(
        firstNameError: () => null,
        lastNameError: () => null,
        isButtonEnabled: false, // Reset button for next page
      ));

      // Navigate to user type page
      Navigator.of(context).pushNamed(RoutesName.onboardingStep2);
      return;
    }

    // Show validation errors
    emit(state.copyWith(
      firstNameError: () => firstNameError,
      lastNameError: () => lastNameError,
    ));
  }

  // ==================== User Type Selection ====================

  /// Handle user type selection change
  void onUserTypeChanged(String userType) {
    emit(state.copyWith(
      selectedUserType: userType,
      isButtonEnabled: true,
    ));
  }

  /// Continue from user type page
  void onContinueUserType({required BuildContext context}) {
    if (state.selectedUserType == null) {
      return;
    }

    AppLogger.info(
        'Onboarding: Selected user type - ${state.selectedUserType}');

    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));

    // Navigate based on user type
    if (state.selectedUserType == 'resident') {
      // Pass user data to claim permit flow
      Navigator.of(context).pushNamed(
        RoutesName.claimPermitSetupAddress,
        arguments: {
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
        },
      );
    } else {
      // TODO: Navigate to visitor flow when created
      AppLogger.info('Onboarding: Visitor flow not yet implemented');
    }
  }

  // ==================== Lifecycle ====================

  /// Reset general onboarding flow
  void resetOnboarding() {
    firstNameController.clear();
    lastNameController.clear();
    termsAccepted = false;
    emit(const GeneralOnboardingState());
  }

  @override
  Future<void> close() {
    firstNameController.dispose();
    lastNameController.dispose();
    return super.close();
  }
}
