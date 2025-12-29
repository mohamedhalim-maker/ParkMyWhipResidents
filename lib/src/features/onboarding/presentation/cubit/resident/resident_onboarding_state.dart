import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/permit_plan_model.dart';

/// State for the resident onboarding flow.
///
/// Holds:
/// - Button enabled state
/// - Selected community
/// - Community search query and filtered list
/// - Temporary selected community (in bottom sheet)
/// - Validation errors for unit and building numbers
/// - Selected permit plan
/// - Validation errors for vehicle fields
/// - License image and filename
class ResidentOnboardingState extends Equatable {
  final bool isButtonEnabled;
  final String? selectedCommunity;
  final String communitySearchQuery;
  final List<String> filteredCommunities;
  final String? tempSelectedCommunity;
  final String? unitNumberError;
  final String? buildingNumberError;
  final PermitPlanModel? selectedPermitPlan;
  final String? plateNumberError;
  final String? vehicleMakeError;
  final String? vehicleModelError;
  final String? vehicleColorError;
  final String? vehicleYearError;
  final bool showVehicleForm;
  final File? licenseImage;
  final String? licenseFileName;
  final bool isLoadingImage;

  const ResidentOnboardingState({
    this.isButtonEnabled = false,
    this.selectedCommunity,
    this.communitySearchQuery = '',
    this.filteredCommunities = const [],
    this.tempSelectedCommunity,
    this.unitNumberError,
    this.buildingNumberError,
    this.selectedPermitPlan,
    this.plateNumberError,
    this.vehicleMakeError,
    this.vehicleModelError,
    this.vehicleColorError,
    this.vehicleYearError,
    this.showVehicleForm = false,
    this.licenseImage,
    this.licenseFileName,
    this.isLoadingImage = false,
  });

  /// Create a copy with updated fields
  ResidentOnboardingState copyWith({
    bool? isButtonEnabled,
    String? selectedCommunity,
    String? communitySearchQuery,
    List<String>? filteredCommunities,
    String? Function()? tempSelectedCommunity,
    String? Function()? unitNumberError,
    String? Function()? buildingNumberError,
    PermitPlanModel? Function()? selectedPermitPlan,
    String? Function()? plateNumberError,
    String? Function()? vehicleMakeError,
    String? Function()? vehicleModelError,
    String? Function()? vehicleColorError,
    String? Function()? vehicleYearError,
    bool? showVehicleForm,
    File? Function()? licenseImage,
    String? Function()? licenseFileName,
    bool? isLoadingImage,
  }) =>
      ResidentOnboardingState(
        isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
        selectedCommunity: selectedCommunity ?? this.selectedCommunity,
        communitySearchQuery: communitySearchQuery ?? this.communitySearchQuery,
        filteredCommunities: filteredCommunities ?? this.filteredCommunities,
        tempSelectedCommunity: tempSelectedCommunity != null
            ? tempSelectedCommunity()
            : this.tempSelectedCommunity,
        unitNumberError:
            unitNumberError != null ? unitNumberError() : this.unitNumberError,
        buildingNumberError: buildingNumberError != null
            ? buildingNumberError()
            : this.buildingNumberError,
        selectedPermitPlan: selectedPermitPlan != null
            ? selectedPermitPlan()
            : this.selectedPermitPlan,
        plateNumberError: plateNumberError != null
            ? plateNumberError()
            : this.plateNumberError,
        vehicleMakeError: vehicleMakeError != null
            ? vehicleMakeError()
            : this.vehicleMakeError,
        vehicleModelError: vehicleModelError != null
            ? vehicleModelError()
            : this.vehicleModelError,
        vehicleColorError: vehicleColorError != null
            ? vehicleColorError()
            : this.vehicleColorError,
        vehicleYearError: vehicleYearError != null
            ? vehicleYearError()
            : this.vehicleYearError,
        showVehicleForm: showVehicleForm ?? this.showVehicleForm,
        licenseImage: licenseImage != null ? licenseImage() : this.licenseImage,
        licenseFileName:
            licenseFileName != null ? licenseFileName() : this.licenseFileName,
        isLoadingImage: isLoadingImage ?? this.isLoadingImage,
      );

  @override
  List<Object?> get props => [
        isButtonEnabled,
        selectedCommunity,
        communitySearchQuery,
        filteredCommunities,
        tempSelectedCommunity,
        unitNumberError,
        buildingNumberError,
        selectedPermitPlan,
        plateNumberError,
        vehicleMakeError,
        vehicleModelError,
        vehicleColorError,
        vehicleYearError,
        showVehicleForm,
        licenseImage,
        licenseFileName,
        isLoadingImage,
      ];
}
