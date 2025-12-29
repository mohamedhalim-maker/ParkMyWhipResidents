import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/permit_plan_model.dart';
import 'package:park_my_whip_residents/src/features/onboarding/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_state.dart';

/// Cubit managing the resident onboarding flow.
/// 
/// Responsibilities:
/// - Manage community selection with search and filtering
/// - Handle address setup
/// - Navigate through resident-specific steps
/// - Accumulate resident data across steps
/// - Submit final resident onboarding data to backend
/// 
/// This is a SINGLETON cubit (registered with registerLazySingleton)
/// so the same instance is shared across all resident onboarding pages.
class ResidentOnboardingCubit extends Cubit<ResidentOnboardingState> {
  // User data passed from general onboarding
  String? firstName;
  String? lastName;

  // ==================== Communities Data ====================
  final List<String> _allCommunities = [
    'YUGO University Club',
    'The Grand Apartments',
    'Pine Ridge Community',
    'Sunset Valley Estates',
    'Maple Grove Residences',
    'Oakwood Heights',
    'Riverdale Commons',
    'Parkside Village',
  ];

  // ==================== Controllers ====================
  final TextEditingController unitNumberController = TextEditingController();
  final TextEditingController buildingNumberController = TextEditingController();
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController vehicleMakeController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController vehicleColorController = TextEditingController();
  
  // Selected vehicle year from dropdown
  int? selectedVehicleYear;

  ResidentOnboardingCubit() : super(const ResidentOnboardingState()) {
    // Initialize filtered communities with all communities
    emit(state.copyWith(filteredCommunities: _allCommunities));
    
    // Listen to text field changes to enable/disable button
    unitNumberController.addListener(_updateButtonStateForBuildingUnit);
    buildingNumberController.addListener(_updateButtonStateForBuildingUnit);
    plateNumberController.addListener(_updateButtonStateForVehicle);
    vehicleMakeController.addListener(_updateButtonStateForVehicle);
    vehicleModelController.addListener(_updateButtonStateForVehicle);
    vehicleColorController.addListener(_updateButtonStateForVehicle);
  }

  // ==================== Initialization ====================

  /// Initialize resident flow with user data from general onboarding
  void initializeWithUserData({
    required String firstName,
    required String lastName,
  }) {
    this.firstName = firstName;
    this.lastName = lastName;
    AppLogger.info('Resident Onboarding: Initialized with user $firstName $lastName');
  }

  // ==================== Community Selection ====================

  /// Handle choose community tap - shows bottom sheet
  void onChooseCommunityTapped({required BuildContext context}) {
    AppLogger.info('Resident Onboarding: Choose community tapped');
    
    // Reset search and temp selection when opening bottom sheet
    emit(state.copyWith(
      communitySearchQuery: '',
      filteredCommunities: _allCommunities,
      tempSelectedCommunity: () => state.selectedCommunity,
    ));
  }

  /// Handle community search query change
  void onCommunitySearchChanged(String query) {
    final filtered = query.isEmpty
        ? _allCommunities
        : _allCommunities
            .where((community) =>
                community.toLowerCase().contains(query.toLowerCase()))
            .toList();
    
    emit(state.copyWith(
      communitySearchQuery: query,
      filteredCommunities: filtered,
    ));
  }

  /// Handle temporary community selection in bottom sheet
  void onTempCommunitySelected(String community) {
    emit(state.copyWith(
      tempSelectedCommunity: () => community,
    ));
  }

  /// Save the selected community (called when pressing Save button)
  void onCommunitySaved() {
    if (state.tempSelectedCommunity != null) {
      emit(state.copyWith(
        selectedCommunity: state.tempSelectedCommunity,
        isButtonEnabled: true,
      ));
      AppLogger.info('Resident Onboarding: Community saved - ${state.tempSelectedCommunity}');
    }
  }

  /// Continue from setup address page
  void onContinueSetupAddress({required BuildContext context}) {
    if (state.selectedCommunity == null) {
      return;
    }
    
    AppLogger.info('Resident Onboarding: Selected community - ${state.selectedCommunity}');
    
    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));
    
    // Navigate to add building & unit page
    Navigator.of(context).pushNamed(RoutesName.onboardingResidentStep2);
  }

  // ==================== Building & Unit Number ====================

  /// Update button enabled state based on building and unit number
  void _updateButtonStateForBuildingUnit() {
    final isValid = _isBuildingUnitValid();
    if (state.isButtonEnabled != isValid) {
      emit(state.copyWith(isButtonEnabled: isValid));
    }
  }

  /// Check if building and unit number fields are valid (no validation errors)
  bool _isBuildingUnitValid() {
    final unitError = OnboardingValidators.validateNumber(unitNumberController.text);
    final buildingError = OnboardingValidators.validateNumber(buildingNumberController.text);
    return unitError == null && buildingError == null;
  }

  /// Handle unit number field change
  void onUnitNumberChanged() {
    // Clear error when user types
    if (state.unitNumberError != null) {
      emit(state.copyWith(unitNumberError: () => null));
    }
  }

  /// Handle building number field change
  void onBuildingNumberChanged() {
    // Clear error when user types
    if (state.buildingNumberError != null) {
      emit(state.copyWith(buildingNumberError: () => null));
    }
  }

  /// Continue from add building & unit page
  void onContinueAddBuildingUnit({required BuildContext context}) {
    // Validate both fields
    final unitError = OnboardingValidators.validateNumber(unitNumberController.text);
    final buildingError = OnboardingValidators.validateNumber(buildingNumberController.text);
    
    // If there are any errors, show red borders (no error messages)
    if (unitError != null || buildingError != null) {
      emit(state.copyWith(
        unitNumberError: () => unitError,
        buildingNumberError: () => buildingError,
      ));
      return;
    }
    
    // Clear any existing errors
    emit(state.copyWith(
      unitNumberError: () => null,
      buildingNumberError: () => null,
    ));
    
    AppLogger.info('Resident Onboarding: Unit ${unitNumberController.text}, Building ${buildingNumberController.text}');
    
    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));
    
    // Navigate to select permit plan page
    Navigator.of(context).pushNamed(RoutesName.onboardingResidentStep3);
  }

  // ==================== Permit Plan Selection ====================

  /// Handle permit plan selection
  void onPermitPlanSelected(PermitPlanModel plan) {
    emit(state.copyWith(
      selectedPermitPlan: () => plan,
      isButtonEnabled: true,
    ));
    AppLogger.info('Resident Onboarding: Selected permit plan - ${plan.period} (\$${plan.price})');
  }

  /// Continue from select permit plan page
  void onContinueSelectPermitPlan({required BuildContext context}) {
    if (state.selectedPermitPlan == null) {
      return;
    }
    
    AppLogger.info('Resident Onboarding: Selected permit plan - ${state.selectedPermitPlan?.period}');
    
    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));
    
    // Navigate to add vehicle info page
    Navigator.of(context).pushNamed(RoutesName.onboardingResidentStep4);
  }

  /// Clear permit plan data when navigating back
  void clearPermitPlanData() {
    emit(state.copyWith(
      selectedPermitPlan: () => null,
      isButtonEnabled: true,
    ));
    AppLogger.info('Resident Onboarding: Cleared permit plan data');
  }

  // ==================== Vehicle Info ====================

  /// Update button enabled state based on vehicle form fields
  void _updateButtonStateForVehicle() {
    final isValid = _isVehicleFormValid();
    if (state.isButtonEnabled != isValid) {
      emit(state.copyWith(isButtonEnabled: isValid));
    }
  }

  /// Check if all vehicle form fields are valid
  bool _isVehicleFormValid() {
    final plateError = OnboardingValidators.validatePlateNumber(plateNumberController.text);
    final makeError = OnboardingValidators.validateVehicleField(vehicleMakeController.text);
    final modelError = OnboardingValidators.validateVehicleField(vehicleModelController.text);
    final colorError = OnboardingValidators.validateVehicleColor(vehicleColorController.text);
    
    return plateError == null && 
           makeError == null && 
           modelError == null && 
           colorError == null && 
           selectedVehicleYear != null;
  }

  /// Handle plate number field change
  void onPlateNumberChanged() {
    if (state.plateNumberError != null) {
      emit(state.copyWith(plateNumberError: () => null));
    }
  }

  /// Handle vehicle make field change
  void onVehicleMakeChanged() {
    if (state.vehicleMakeError != null) {
      emit(state.copyWith(vehicleMakeError: () => null));
    }
  }

  /// Handle vehicle model field change
  void onVehicleModelChanged() {
    if (state.vehicleModelError != null) {
      emit(state.copyWith(vehicleModelError: () => null));
    }
  }

  /// Handle vehicle color field change
  void onVehicleColorChanged() {
    if (state.vehicleColorError != null) {
      emit(state.copyWith(vehicleColorError: () => null));
    }
  }

  /// Handle vehicle year selection from dropdown
  void onVehicleYearSelected(int? year) {
    selectedVehicleYear = year;
    _updateButtonStateForVehicle();
    AppLogger.info('Resident Onboarding: Selected vehicle year - $year');
  }

  /// Continue from add vehicle info page
  void onContinueAddVehicleInfo({required BuildContext context}) {
    // Validate all fields
    final plateError = OnboardingValidators.validatePlateNumber(plateNumberController.text);
    final makeError = OnboardingValidators.validateVehicleField(vehicleMakeController.text);
    final modelError = OnboardingValidators.validateVehicleField(vehicleModelController.text);
    final colorError = OnboardingValidators.validateVehicleColor(vehicleColorController.text);
    
    // If there are any errors, show red borders
    if (plateError != null || makeError != null || modelError != null || colorError != null || selectedVehicleYear == null) {
      emit(state.copyWith(
        plateNumberError: () => plateError,
        vehicleMakeError: () => makeError,
        vehicleModelError: () => modelError,
        vehicleColorError: () => colorError,
      ));
      return;
    }
    
    // Clear any existing errors
    emit(state.copyWith(
      plateNumberError: () => null,
      vehicleMakeError: () => null,
      vehicleModelError: () => null,
      vehicleColorError: () => null,
    ));
    
    AppLogger.info('Resident Onboarding: Vehicle info - ${plateNumberController.text}, ${vehicleMakeController.text} ${vehicleModelController.text}, Year: $selectedVehicleYear, Color: ${vehicleColorController.text}');
    
    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));
    
    // TODO: Navigate to next step in resident flow
    AppLogger.info('Resident Onboarding: Next step not yet implemented');
  }

  /// Clear vehicle data when navigating back
  void clearVehicleData() {
    plateNumberController.clear();
    vehicleMakeController.clear();
    vehicleModelController.clear();
    vehicleColorController.clear();
    selectedVehicleYear = null;
    emit(state.copyWith(
      plateNumberError: () => null,
      vehicleMakeError: () => null,
      vehicleModelError: () => null,
      vehicleColorError: () => null,
      isButtonEnabled: false,
    ));
    AppLogger.info('Resident Onboarding: Cleared vehicle data');
  }

  // ==================== Back Navigation ====================

  /// Clear building and unit data when navigating back
  void clearBuildingUnitData() {
    unitNumberController.clear();
    buildingNumberController.clear();
    emit(state.copyWith(
      unitNumberError: () => null,
      buildingNumberError: () => null,
      isButtonEnabled: false,
    ));
    AppLogger.info('Resident Onboarding: Cleared building & unit data');
  }

  // ==================== Final Submission ====================

  /// Submit all resident onboarding data to backend
  Future<void> submitResidentOnboarding({required BuildContext context}) async {
    // TODO: Implement submitResidentOnboarding
    // 1. Set isLoading = true
    // 2. Collect all data (firstName, lastName, selectedCommunity, etc.)
    // 3. Call onboardingService.saveOnboardingData()
    // 4. Handle success: navigate to dashboard
    // 5. Handle error: show error message
    // 6. Set isLoading = false
  }

  // ==================== Lifecycle ====================

  /// Reset resident onboarding flow
  void resetOnboarding() {
    firstName = null;
    lastName = null;
    unitNumberController.clear();
    buildingNumberController.clear();
    emit(const ResidentOnboardingState());
  }

  @override
  Future<void> close() {
    unitNumberController.dispose();
    buildingNumberController.dispose();
    plateNumberController.dispose();
    vehicleMakeController.dispose();
    vehicleModelController.dispose();
    vehicleColorController.dispose();
    return super.close();
  }
}
