import 'package:equatable/equatable.dart';

/// State for the general onboarding flow (Steps 1-2).
/// 
/// Holds:
/// - Button enabled state
/// - Field-specific errors for validation
/// - Selected user type (resident or visitor)
class GeneralOnboardingState extends Equatable {
  final bool isButtonEnabled;
  final String? firstNameError;
  final String? lastNameError;
  final String? selectedUserType;

  const GeneralOnboardingState({
    this.isButtonEnabled = false,
    this.firstNameError,
    this.lastNameError,
    this.selectedUserType,
  });

  /// Create a copy with updated fields
  GeneralOnboardingState copyWith({
    bool? isButtonEnabled,
    String? Function()? firstNameError,
    String? Function()? lastNameError,
    String? selectedUserType,
  }) =>
      GeneralOnboardingState(
        isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
        firstNameError: firstNameError != null ? firstNameError() : this.firstNameError,
        lastNameError: lastNameError != null ? lastNameError() : this.lastNameError,
        selectedUserType: selectedUserType ?? this.selectedUserType,
      );

  @override
  List<Object?> get props => [
        isButtonEnabled,
        firstNameError,
        lastNameError,
        selectedUserType,
      ];
}
