import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/routes/names.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/permit_plan_model.dart';
import 'package:park_my_whip_residents/src/features/onboarding/domain/validators.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/claim_permit_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/helpers/claim_permit_file_picker_service.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/helpers/claim_permit_form_controllers.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/helpers/claim_permit_document_handler.dart';

/// Cubit managing the claim permit onboarding flow.
///
/// Responsibilities:
/// - Manage community selection with search and filtering
/// - Handle address setup
/// - Navigate through permit claim steps
/// - Accumulate user data across steps
/// - Submit final claim permit data to backend
///
/// This is a SINGLETON cubit (registered with registerLazySingleton)
/// so the same instance is shared across all claim permit pages.
class ClaimPermitCubit extends Cubit<ClaimPermitState> {
  // User data passed from general onboarding
  String? firstName;
  String? lastName;

  // ==================== Helper Services ====================
  final ClaimPermitFormControllers _controllers = ClaimPermitFormControllers();
  final ClaimPermitFilePickerService _filePickerService =
      ClaimPermitFilePickerService();
  late final ClaimPermitDocumentHandler _documentHandler;

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

  // ==================== Controllers (exposed for UI) ====================
  TextEditingController get unitNumberController => _controllers.unitNumber;
  TextEditingController get buildingNumberController =>
      _controllers.buildingNumber;
  TextEditingController get plateNumberController => _controllers.plateNumber;
  TextEditingController get vehicleMakeController => _controllers.vehicleMake;
  TextEditingController get vehicleModelController => _controllers.vehicleModel;
  TextEditingController get vehicleColorController => _controllers.vehicleColor;
  TextEditingController get vehicleYearController => _controllers.vehicleYear;

  ClaimPermitCubit() : super(const ClaimPermitState()) {
    _documentHandler = ClaimPermitDocumentHandler(_filePickerService);

    // Initialize filtered communities with all communities
    emit(state.copyWith(filteredCommunities: _allCommunities));

    // Listen to text field changes to enable/disable button
    _controllers.addBuildingUnitListeners(_updateButtonStateForBuildingUnit);
    _controllers.addVehicleListeners(_updateButtonStateForVehicle);
  }

  // ==================== Helper Methods ====================

  /// Set loading state for image/file picking
  void _setLoadingImage(bool isLoading) {
    emit(state.copyWith(isLoadingImage: isLoading));
  }

  /// Generic method to clear error if present
  void _clearErrorIfPresent({
    required String? currentError,
    required VoidCallback clearError,
  }) {
    if (currentError != null) {
      clearError();
    }
  }

  /// Navigate and reset button state
  void _navigateAndResetButton(BuildContext context, String routeName) {
    emit(state.copyWith(isButtonEnabled: false));
    Navigator.of(context).pushNamed(routeName);
  }

  // ==================== Initialization ====================

  /// Initialize claim permit flow with user data from general onboarding
  void initializeWithUserData({
    required String firstName,
    required String lastName,
  }) {
    this.firstName = firstName;
    this.lastName = lastName;
    AppLogger.info('Claim Permit: Initialized with user $firstName $lastName');
  }

  /// Enable the next/continue button
  void enableButton() {
    emit(state.copyWith(isButtonEnabled: true));
  }

  // ==================== Community Selection ====================

  /// Handle choose community tap - shows bottom sheet
  void onChooseCommunityTapped({required BuildContext context}) {
    AppLogger.info('Claim Permit: Choose community tapped');

    // Reset search and temp selection when opening bottom sheet
    emit(state.copyWith(
      communitySearchQuery: '',
      filteredCommunities: _allCommunities,
      tempSelectedCommunity: () => state.data.selectedCommunity,
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
        data: state.data.copyWith(
          selectedCommunity: state.tempSelectedCommunity,
        ),
        isButtonEnabled: true,
      ));
      AppLogger.info(
          'Claim Permit: Community saved - ${state.tempSelectedCommunity}');
    }
  }

  /// Continue from setup address page
  void onContinueSetupAddress({required BuildContext context}) {
    if (state.data.selectedCommunity == null) {
      return;
    }

    AppLogger.info(
        'Claim Permit: Selected community - ${state.data.selectedCommunity}');
    _navigateAndResetButton(context, RoutesName.claimPermitAddBuildingUnit);
  }

  // ==================== Building & Unit Number ====================

  /// Update button enabled state based on building and unit number
  void _updateButtonStateForBuildingUnit() {
    final hasData = _controllers.hasBuildingUnitData();
    if (state.isButtonEnabled != hasData) {
      emit(state.copyWith(isButtonEnabled: hasData));
    }
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
        OnboardingValidators.validateUnitNumber(_controllers.unitNumber.text);
    final buildingError = OnboardingValidators.validateUnitNumber(
        _controllers.buildingNumber.text);

    // If there are any errors, show red borders (no error messages)
    if (unitError != null || buildingError != null) {
      emit(state.copyWith(
        unitNumberError: () => unitError,
        buildingNumberError: () => buildingError,
      ));
      return;
    }

    // Clear any existing errors and save data
    emit(state.copyWith(
      data: state.data.copyWith(
        unitNumber: _controllers.unitNumber.text,
        buildingNumber: _controllers.buildingNumber.text,
      ),
      unitNumberError: () => null,
      buildingNumberError: () => null,
    ));

    AppLogger.info(
        'Claim Permit: Unit ${_controllers.unitNumber.text}, Building ${_controllers.buildingNumber.text}');
    _navigateAndResetButton(context, RoutesName.claimPermitSelectPermitPlan);
  }

  // ==================== Permit Plan Selection ====================

  /// Handle permit plan selection
  void onPermitPlanSelected(PermitPlanModel plan) {
    emit(state.copyWith(
      data: state.data.copyWith(
        selectedPermitPlan: plan,
      ),
      isButtonEnabled: true,
    ));
    AppLogger.info(
        'Claim Permit: Selected permit plan - ${plan.period} (\$${plan.price})');
  }

  /// Continue from select permit plan page
  void onContinueSelectPermitPlan({required BuildContext context}) {
    if (state.data.selectedPermitPlan == null) {
      return;
    }

    AppLogger.info(
        'Claim Permit: Selected permit plan - ${state.data.selectedPermitPlan?.period}');
    _navigateAndResetButton(context, RoutesName.claimPermitAddVehicleInfo);
  }

  /// Clear permit plan data when navigating back
  void clearPermitPlanData() {
    emit(state.copyWith(
      data: state.data.copyWith(
        selectedPermitPlan: null,
      ),
      isButtonEnabled: true,
    ));
    AppLogger.info('Claim Permit: Cleared permit plan data');
  }

  // ==================== Vehicle Info ====================

  /// Update button enabled state based on vehicle form fields
  void _updateButtonStateForVehicle() {
    final isValid = _controllers.hasVehicleData();
    if (state.isButtonEnabled != isValid) {
      emit(state.copyWith(isButtonEnabled: isValid));
    }
  }

  void onVehicleHeaderTapped() {
    emit(state.copyWith(showVehicleForm: true));
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
        OnboardingValidators.validatePlateNumber(_controllers.plateNumber.text);
    final makeError = OnboardingValidators.validateVehicleField(
        _controllers.vehicleMake.text);
    final modelError = OnboardingValidators.validateVehicleField(
        _controllers.vehicleModel.text);
    final colorError = OnboardingValidators.validateVehicleColor(
        _controllers.vehicleColor.text);
    final yearError =
        OnboardingValidators.validateVehicleYear(_controllers.vehicleYear.text);

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

    // All fields valid, save data, clear errors and proceed
    emit(state.copyWith(
      data: state.data.copyWith(
        plateNumber: _controllers.plateNumber.text,
        vehicleMake: _controllers.vehicleMake.text,
        vehicleModel: _controllers.vehicleModel.text,
        vehicleColor: _controllers.vehicleColor.text,
        vehicleYear: _controllers.vehicleYear.text,
      ),
      plateNumberError: () => null,
      vehicleMakeError: () => null,
      vehicleModelError: () => null,
      vehicleColorError: () => null,
      vehicleYearError: () => null,
    ));

    AppLogger.info('Claim Permit: Vehicle info validated successfully');
    _navigateAndResetButton(context, RoutesName.claimPermitUploadLicense);
  }

  /// Clear vehicle data when navigating back
  void clearVehicleData() {
    _controllers.clearVehicle();
    emit(state.copyWith(
      plateNumberError: () => null,
      vehicleMakeError: () => null,
      vehicleModelError: () => null,
      vehicleColorError: () => null,
      vehicleYearError: () => null,
      isButtonEnabled: false,
    ));
    AppLogger.info('Claim Permit: Cleared vehicle data');
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

  /// Handle license upload by showing image source bottom sheet
  Future<void> handleLicenseUpload(BuildContext context) async {
    final file = await _documentHandler.showImageSourcePicker(
      context: context,
      setLoading: _setLoadingImage,
    );

    if (file != null) {
      final fileName = _filePickerService.getFileName(file.path);
      _setDocument(
        file: file,
        fileName: fileName,
        documentType: DocumentType.license,
      );
    }
  }

  /// Continue from upload license page
  void onContinueUploadLicense({required BuildContext context}) {
    if (state.licenseImage == null) {
      return;
    }

    AppLogger.info(
        'Claim Permit: License uploaded - ${state.data.licenseImagePath}');
    _navigateAndResetButton(context, RoutesName.claimPermitUploadRegistration);
  }

  /// Clear license data when navigating back
  void clearLicenseData() {
    _clearDocument(DocumentType.license);
    emit(state.copyWith(isButtonEnabled: true));
    AppLogger.info('Claim Permit: Cleared license data');
  }

  // ==================== Vehicle Registration Upload ====================

  /// Handle registration upload by showing image source bottom sheet
  Future<void> handleRegistrationUpload(BuildContext context) async {
    final file = await _documentHandler.showImageSourcePicker(
      context: context,
      setLoading: _setLoadingImage,
    );

    if (file != null) {
      final fileName = _filePickerService.getFileName(file.path);
      _setDocument(
        file: file,
        fileName: fileName,
        documentType: DocumentType.registration,
      );
    }
  }

  /// Continue from upload vehicle registration page
  void onContinueUploadRegistration({required BuildContext context}) {
    if (state.registrationImage == null) {
      return;
    }

    AppLogger.info(
        'Claim Permit: Vehicle registration uploaded - ${state.data.registrationImagePath}');
    _navigateAndResetButton(context, RoutesName.claimPermitUploadInsurance);
  }

  /// Clear vehicle registration data when navigating back
  void clearRegistrationData() {
    _clearDocument(DocumentType.registration);
    emit(state.copyWith(isButtonEnabled: true));
    AppLogger.info('Claim Permit: Cleared vehicle registration data');
  }

  // ==================== Insurance Upload ====================

  /// Handle insurance upload by showing image source bottom sheet + file option
  Future<void> handleInsuranceUpload(BuildContext context) async {
    final result = await _documentHandler.showInsurancePicker(
      context: context,
      setLoading: _setLoadingImage,
    );

    if (result.file != null) {
      final fileName = _filePickerService.getFileName(result.file!.path);
      _setDocument(
        file: result.file!,
        fileName: fileName,
        documentType: DocumentType.insurance,
        isImage: result.isImage,
      );
    }
  }

  /// Continue from upload insurance page
  void onContinueUploadInsurance({required BuildContext context}) {
    if (state.insuranceFile == null) {
      return;
    }

    AppLogger.info(
        'Claim Permit: Insurance uploaded - ${state.data.insuranceFilePath}');
    _navigateAndResetButton(context, RoutesName.claimPermitConfirmDetails);
    AppLogger.info('Claim Permit: Navigating to confirmation page');
  }

  /// Clear insurance data when navigating back
  void clearInsuranceData() {
    _clearDocument(DocumentType.insurance);
    emit(state.copyWith(isButtonEnabled: true));
    AppLogger.info('Claim Permit: Cleared insurance data');
  }

  // ==================== Document Management Helper ====================

  /// Set document (license/registration/insurance)
  void _setDocument({
    required File file,
    required String fileName,
    required DocumentType documentType,
    bool isImage = true,
  }) {
    switch (documentType) {
      case DocumentType.license:
        emit(state.copyWith(
          licenseImage: () => file,
          data: state.data.copyWith(licenseImagePath: file.path),
          isButtonEnabled: true,
        ));
        AppLogger.info('Claim Permit: License image set - $fileName');
        break;
      case DocumentType.registration:
        emit(state.copyWith(
          registrationImage: () => file,
          data: state.data.copyWith(registrationImagePath: file.path),
          isButtonEnabled: true,
        ));
        AppLogger.info(
            'Claim Permit: Vehicle registration image set - $fileName');
        break;
      case DocumentType.insurance:
        emit(state.copyWith(
          insuranceFile: () => file,
          data: state.data.copyWith(
            insuranceFilePath: file.path,
            insuranceIsImage: isImage,
          ),
          isButtonEnabled: true,
        ));
        AppLogger.info('Claim Permit: Insurance file set - $fileName');
        break;
    }
  }

  /// Remove document (license/registration/insurance)
  void removeDocument(DocumentType documentType) {
    _clearDocument(documentType);
    emit(state.copyWith(isButtonEnabled: false));
  }

  /// Clear document from state
  void _clearDocument(DocumentType documentType) {
    switch (documentType) {
      case DocumentType.license:
        emit(state.copyWith(
          licenseImage: () => null,
          data: state.data.copyWith(licenseImagePath: null),
        ));
        break;
      case DocumentType.registration:
        emit(state.copyWith(
          registrationImage: () => null,
          data: state.data.copyWith(registrationImagePath: null),
        ));
        break;
      case DocumentType.insurance:
        emit(state.copyWith(
          insuranceFile: () => null,
          data: state.data.copyWith(
            insuranceFilePath: null,
            insuranceIsImage: true,
          ),
        ));
        break;
    }
  }

  // ==================== Back Navigation ====================

  /// Clear building and unit data when navigating back
  void clearBuildingUnitData() {
    _controllers.clearBuildingUnit();
    emit(state.copyWith(
      unitNumberError: () => null,
      buildingNumberError: () => null,
      isButtonEnabled: true,
    ));
    AppLogger.info('Claim Permit: Cleared building & unit data');
  }

  // ==================== Final Submission ====================

  /// Submit all claim permit data to backend
  Future<void> submitClaimPermit({required BuildContext context}) async {
    // TODO: Implement submitClaimPermit
    // 1. Set isLoading = true
    // 2. Collect all data (firstName, lastName, selectedCommunity, etc.)
    // 3. Call onboardingService.saveOnboardingData()
    // 4. Handle success: navigate to dashboard
    // 5. Handle error: show error message
    // 6. Set isLoading = false
  }

  // ==================== Lifecycle ====================

  /// Reset claim permit flow
  void resetOnboarding() {
    firstName = null;
    lastName = null;
    _controllers.clearBuildingUnit();
    _controllers.clearVehicle();
    emit(const ClaimPermitState());
  }

  @override
  Future<void> close() {
    _controllers.dispose();
    return super.close();
  }
}
