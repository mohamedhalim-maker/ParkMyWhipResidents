import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/core/widgets/error_dialog.dart';
import 'package:park_my_whip_residents/src/core/widgets/image_source_bottom_sheet.dart';
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
  final TextEditingController buildingNumberController =
      TextEditingController();
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController vehicleMakeController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController vehicleColorController = TextEditingController();
  final TextEditingController vehicleYearController = TextEditingController();

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

  // ==================== Helper Methods ====================

  /// Generic method to clear error if present
  void _clearErrorIfPresent({
    required String? currentError,
    required VoidCallback clearError,
  }) {
    if (currentError != null) {
      clearError();
    }
  }

  // ==================== Initialization ====================

  /// Initialize resident flow with user data from general onboarding
  void initializeWithUserData({
    required String firstName,
    required String lastName,
  }) {
    this.firstName = firstName;
    this.lastName = lastName;
    AppLogger.info(
        'Resident Onboarding: Initialized with user $firstName $lastName');
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
      AppLogger.info(
          'Resident Onboarding: Community saved - ${state.tempSelectedCommunity}');
    }
  }

  /// Continue from setup address page
  void onContinueSetupAddress({required BuildContext context}) {
    if (state.selectedCommunity == null) {
      return;
    }

    AppLogger.info(
        'Resident Onboarding: Selected community - ${state.selectedCommunity}');

    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));

    // Navigate to add building & unit page
    Navigator.of(context).pushNamed(RoutesName.onboardingResidentStep2);
  }

  // ==================== Building & Unit Number ====================

  /// Update button enabled state based on building and unit number
  void _updateButtonStateForBuildingUnit() {
    final hasData = _hasBuildingUnitData();
    if (state.isButtonEnabled != hasData) {
      emit(state.copyWith(isButtonEnabled: hasData));
    }
  }

  /// Check if building and unit number fields have data (not empty)
  bool _hasBuildingUnitData() {
    return unitNumberController.text.trim().isNotEmpty &&
        buildingNumberController.text.trim().isNotEmpty;
  }

  /// Handle unit number field change
  void onUnitNumberChanged() {
    _clearErrorIfPresent(
      currentError: state.unitNumberError,
      clearError: () => emit(state.copyWith(unitNumberError: () => null)),
    );
  }

  /// Handle building number field change
  void onBuildingNumberChanged() {
    _clearErrorIfPresent(
      currentError: state.buildingNumberError,
      clearError: () => emit(state.copyWith(buildingNumberError: () => null)),
    );
  }

  /// Continue from add building & unit page
  void onContinueAddBuildingUnit({required BuildContext context}) {
    // Validate both fields
    final unitError =
        OnboardingValidators.validateNumber(unitNumberController.text);
    final buildingError =
        OnboardingValidators.validateNumber(buildingNumberController.text);

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

    AppLogger.info(
        'Resident Onboarding: Unit ${unitNumberController.text}, Building ${buildingNumberController.text}');

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
    AppLogger.info(
        'Resident Onboarding: Selected permit plan - ${plan.period} (\$${plan.price})');
  }

  /// Continue from select permit plan page
  void onContinueSelectPermitPlan({required BuildContext context}) {
    if (state.selectedPermitPlan == null) {
      return;
    }

    AppLogger.info(
        'Resident Onboarding: Selected permit plan - ${state.selectedPermitPlan?.period}');

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
    final isValid = _hasVehicleFormData();
    if (state.isButtonEnabled != isValid) {
      emit(state.copyWith(isButtonEnabled: isValid));
    }
  }

  void onVehicleHeaderTapped() {
    emit(state.copyWith(showVehicleForm: true));
  }

  /// Check if all vehicle form fields have data (not empty)
  bool _hasVehicleFormData() {
    return plateNumberController.text.trim().isNotEmpty &&
        vehicleMakeController.text.trim().isNotEmpty &&
        vehicleModelController.text.trim().isNotEmpty &&
        vehicleColorController.text.trim().isNotEmpty &&
        vehicleYearController.text.trim().isNotEmpty;
  }

  /// Handle plate number field change
  void onPlateNumberChanged() {
    _clearErrorIfPresent(
      currentError: state.plateNumberError,
      clearError: () => emit(state.copyWith(plateNumberError: () => null)),
    );
  }

  /// Handle vehicle make field change
  void onVehicleMakeChanged() {
    _clearErrorIfPresent(
      currentError: state.vehicleMakeError,
      clearError: () => emit(state.copyWith(vehicleMakeError: () => null)),
    );
  }

  /// Handle vehicle model field change
  void onVehicleModelChanged() {
    _clearErrorIfPresent(
      currentError: state.vehicleModelError,
      clearError: () => emit(state.copyWith(vehicleModelError: () => null)),
    );
  }

  /// Handle vehicle color field change
  void onVehicleColorChanged() {
    _clearErrorIfPresent(
      currentError: state.vehicleColorError,
      clearError: () => emit(state.copyWith(vehicleColorError: () => null)),
    );
  }

  /// Handle vehicle year field change
  void onVehicleYearChanged() {
    _clearErrorIfPresent(
      currentError: state.vehicleYearError,
      clearError: () => emit(state.copyWith(vehicleYearError: () => null)),
    );
  }

  /// Continue from add vehicle info page
  void onContinueAddVehicleInfo({required BuildContext context}) {
    // Validate all fields
    final plateError =
        OnboardingValidators.validatePlateNumber(plateNumberController.text);
    final makeError =
        OnboardingValidators.validateVehicleField(vehicleMakeController.text);
    final modelError =
        OnboardingValidators.validateVehicleField(vehicleModelController.text);
    final colorError =
        OnboardingValidators.validateVehicleColor(vehicleColorController.text);
    final yearError =
        OnboardingValidators.validateVehicleYear(vehicleYearController.text);

    // If there are any errors, show them
    if (plateError != null ||
        makeError != null ||
        modelError != null ||
        colorError != null ||
        yearError != null) {
      emit(state.copyWith(
        plateNumberError: () => plateError,
        vehicleMakeError: () => makeError,
        vehicleModelError: () => modelError,
        vehicleColorError: () => colorError,
        vehicleYearError: () => yearError,
      ));
      return;
    }

    // All fields valid, clear errors and proceed
    emit(state.copyWith(
      plateNumberError: () => null,
      vehicleMakeError: () => null,
      vehicleModelError: () => null,
      vehicleColorError: () => null,
      vehicleYearError: () => null,
    ));

    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));

    // Navigate to upload license page
    Navigator.of(context).pushNamed(RoutesName.onboardingResidentStep5);
    AppLogger.info('Resident Onboarding: Vehicle info validated successfully');
  }

  /// Clear vehicle data when navigating back
  void clearVehicleData() {
    plateNumberController.clear();
    vehicleMakeController.clear();
    vehicleModelController.clear();
    vehicleColorController.clear();
    vehicleYearController.clear();
    emit(state.copyWith(
      plateNumberError: () => null,
      vehicleMakeError: () => null,
      vehicleModelError: () => null,
      vehicleColorError: () => null,
      vehicleYearError: () => null,
      isButtonEnabled: false,
    ));
    AppLogger.info('Resident Onboarding: Cleared vehicle data');
  }

  /// Handle back navigation from vehicle info page
  /// Returns true if should navigate to previous page, false if just hiding form
  bool backFromVehicleInfo() {
    if (state.showVehicleForm) {
      // Hide the form and clear vehicle controllers, don't navigate
      clearVehicleData();
      emit(state.copyWith(showVehicleForm: false));
      return false;
    } else {
      // Navigate back and enable button for step 3
      emit(state.copyWith(isButtonEnabled: true));
      return true;
    }
  }

  // ==================== License Upload ====================

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from camera
  Future<File?> pickImageFromCamera(BuildContext context) async {
    return pickImage(ImageSource.camera, context);
  }

  /// Pick an image from gallery
  Future<File?> pickImageFromGallery(BuildContext context) async {
    return pickImage(ImageSource.gallery, context);
  }

  /// Pick an image from gallery or camera
  /// Returns the picked image file or null if cancelled/failed
  Future<File?> pickImage(ImageSource source, BuildContext context) async {
    try {
      emit(state.copyWith(isLoadingImage: true));

      // Pick image - image_picker handles permissions automatically
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      emit(state.copyWith(isLoadingImage: false));

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Check file size (5 MB = 5 * 1024 * 1024 bytes)
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5 MB in bytes

        if (fileSize > maxSize) {
          if (context.mounted) {
            await showErrorDialog(
              context: context,
              title: ImagePickerStrings.fileTooLarge,
              message: ImagePickerStrings.fileSizeTooLargeMessage(
                fileSize / (1024 * 1024),
              ),
            );
          }
          return null;
        }

        final fileName = pickedFile.name;
        AppLogger.info('Image picked: $fileName');
        return file;
      }

      return null;
    } catch (e) {
      emit(state.copyWith(isLoadingImage: false));
      AppLogger.error('Error picking image: $e');

      if (context.mounted) {
        await showErrorDialog(
          context: context,
          title: ImagePickerStrings.error,
          message: ImagePickerStrings.failedToPickImage,
        );
      }

      return null;
    }
  }

  /// Handle license upload by showing image source bottom sheet
  void handleLicenseUpload(BuildContext context) {
    showImageSourceBottomSheet(
      context: context,
      onCameraTap: () async {
        final file = await pickImageFromCamera(context);
        if (file != null) {
          final fileName = file.path.split('/').last;
          setLicenseImage(file, fileName);
        }
      },
      onGalleryTap: () async {
        final file = await pickImageFromGallery(context);
        if (file != null) {
          final fileName = file.path.split('/').last;
          setLicenseImage(file, fileName);
        }
      },
    );
  }

  /// Set the license image and filename
  void setLicenseImage(File image, String fileName) {
    emit(state.copyWith(
      licenseImage: () => image,
      licenseFileName: () => fileName,
      isButtonEnabled: true,
    ));
    AppLogger.info('Resident Onboarding: License image set - $fileName');
  }

  /// Remove the license image
  void removeLicenseImage() {
    emit(state.copyWith(
      licenseImage: () => null,
      licenseFileName: () => null,
      isButtonEnabled: false,
    ));
    AppLogger.info('Resident Onboarding: License image removed');
  }

  /// Continue from upload license page
  void onContinueUploadLicense({required BuildContext context}) {
    if (state.licenseImage == null) {
      return;
    }

    AppLogger.info(
        'Resident Onboarding: License uploaded - ${state.licenseFileName}');

    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));

    // Navigate to upload vehicle registration page
    Navigator.of(context).pushNamed(RoutesName.onboardingResidentStep6);
  }

  /// Clear license data when navigating back
  void clearLicenseData() {
    emit(state.copyWith(
      licenseImage: () => null,
      licenseFileName: () => null,
      isButtonEnabled: true,
    ));
    AppLogger.info('Resident Onboarding: Cleared license data');
  }

  // ==================== Vehicle Registration Upload ====================

  /// Handle registration upload by showing image source bottom sheet
  void handleRegistrationUpload(BuildContext context) {
    showImageSourceBottomSheet(
      context: context,
      onCameraTap: () async {
        final file = await pickImageFromCamera(context);
        if (file != null) {
          final fileName = file.path.split('/').last;
          setRegistrationImage(file, fileName);
        }
      },
      onGalleryTap: () async {
        final file = await pickImageFromGallery(context);
        if (file != null) {
          final fileName = file.path.split('/').last;
          setRegistrationImage(file, fileName);
        }
      },
    );
  }

  /// Set the vehicle registration image and filename
  void setRegistrationImage(File image, String fileName) {
    emit(state.copyWith(
      registrationImage: () => image,
      registrationFileName: () => fileName,
      isButtonEnabled: true,
    ));
    AppLogger.info(
        'Resident Onboarding: Vehicle registration image set - $fileName');
  }

  /// Remove the vehicle registration image
  void removeRegistrationImage() {
    emit(state.copyWith(
      registrationImage: () => null,
      registrationFileName: () => null,
      isButtonEnabled: false,
    ));
    AppLogger.info('Resident Onboarding: Vehicle registration image removed');
  }

  /// Continue from upload vehicle registration page
  void onContinueUploadRegistration({required BuildContext context}) {
    if (state.registrationImage == null) {
      return;
    }

    AppLogger.info(
        'Resident Onboarding: Vehicle registration uploaded - ${state.registrationFileName}');

    // Reset button state for next page
    emit(state.copyWith(isButtonEnabled: false));

    // TODO: Navigate to next step in resident flow
    AppLogger.info('Resident Onboarding: Vehicle registration upload completed');
  }

  /// Clear vehicle registration data when navigating back
  void clearRegistrationData() {
    emit(state.copyWith(
      registrationImage: () => null,
      registrationFileName: () => null,
      isButtonEnabled: true,
    ));
    AppLogger.info('Resident Onboarding: Cleared vehicle registration data');
  }

  // ==================== Back Navigation ====================

  /// Clear building and unit data when navigating back
  void clearBuildingUnitData() {
    unitNumberController.clear();
    buildingNumberController.clear();
    emit(state.copyWith(
      unitNumberError: () => null,
      buildingNumberError: () => null,
      isButtonEnabled: true,
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
