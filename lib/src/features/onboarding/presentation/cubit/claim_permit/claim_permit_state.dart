import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/onboarding_data_model.dart';

/// State for the claim permit onboarding flow.
///
/// Holds:
/// - OnboardingDataModel (all user data)
/// - UI state (button enabled, form visibility, loading)
/// - Community search state (query, filtered list, temp selection)
/// - Validation errors for all fields
/// - File objects (license, registration, insurance)
class ClaimPermitState extends Equatable {
  /// Holds all the onboarding data collected from the user
  final OnboardingDataModel data;

  /// Whether the continue/next button is enabled
  final bool isButtonEnabled;

  /// Community search query
  final String communitySearchQuery;

  /// Filtered list of communities based on search query
  final List<String> filteredCommunities;

  /// Temporary selected community in the bottom sheet (before confirmation)
  final String? tempSelectedCommunity;

  // Validation errors
  final String? unitNumberError;
  final String? buildingNumberError;
  final String? plateNumberError;
  final String? vehicleMakeError;
  final String? vehicleModelError;
  final String? vehicleColorError;
  final String? vehicleYearError;

  /// Whether to show the vehicle form or just the header
  final bool showVehicleForm;

  /// Loading state for image picking
  final bool isLoadingImage;

  // File objects for uploaded documents
  final File? licenseImage;
  final File? registrationImage;
  final File? insuranceFile;

  const ClaimPermitState({
    this.data = const OnboardingDataModel(),
    this.isButtonEnabled = false,
    this.communitySearchQuery = '',
    this.filteredCommunities = const [],
    this.tempSelectedCommunity,
    this.unitNumberError,
    this.buildingNumberError,
    this.plateNumberError,
    this.vehicleMakeError,
    this.vehicleModelError,
    this.vehicleColorError,
    this.vehicleYearError,
    this.showVehicleForm = false,
    this.isLoadingImage = false,
    this.licenseImage,
    this.registrationImage,
    this.insuranceFile,
  });

  /// Create a copy with updated fields
  ClaimPermitState copyWith({
    OnboardingDataModel? data,
    bool? isButtonEnabled,
    String? communitySearchQuery,
    List<String>? filteredCommunities,
    String? Function()? tempSelectedCommunity,
    String? Function()? unitNumberError,
    String? Function()? buildingNumberError,
    String? Function()? plateNumberError,
    String? Function()? vehicleMakeError,
    String? Function()? vehicleModelError,
    String? Function()? vehicleColorError,
    String? Function()? vehicleYearError,
    bool? showVehicleForm,
    bool? isLoadingImage,
    File? Function()? licenseImage,
    File? Function()? registrationImage,
    File? Function()? insuranceFile,
  }) =>
      ClaimPermitState(
        data: data ?? this.data,
        isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
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
        isLoadingImage: isLoadingImage ?? this.isLoadingImage,
        licenseImage: licenseImage != null ? licenseImage() : this.licenseImage,
        registrationImage: registrationImage != null
            ? registrationImage()
            : this.registrationImage,
        insuranceFile:
            insuranceFile != null ? insuranceFile() : this.insuranceFile,
      );

  @override
  List<Object?> get props => [
        data,
        isButtonEnabled,
        communitySearchQuery,
        filteredCommunities,
        tempSelectedCommunity,
        unitNumberError,
        buildingNumberError,
        plateNumberError,
        vehicleMakeError,
        vehicleModelError,
        vehicleColorError,
        vehicleYearError,
        showVehicleForm,
        isLoadingImage,
        licenseImage,
        registrationImage,
        insuranceFile,
      ];
}
