import 'package:park_my_whip_residents/src/features/onboarding/data/models/permit_plan_model.dart';
import 'package:park_my_whip_residents/src/features/onboarding/data/models/user_type.dart';

/// Model to hold all onboarding data collected during the onboarding flow
///
/// This model aggregates data from both general onboarding steps (name, user type)
/// and flow-specific steps (resident or visitor information).
class OnboardingDataModel {
  // ==================== General Info (Steps 1-2) ====================

  /// User's first name
  final String? firstName;

  /// User's last name
  final String? lastName;

  /// Type of user: Resident or Visitor
  final UserType? userType;

  // ==================== Resident Info ====================

  /// Selected community name (Resident Step 1)
  final String? selectedCommunity;

  /// Unit number (Resident Step 2)
  final String? unitNumber;

  /// Building number (Resident Step 2)
  final String? buildingNumber;

  /// Selected permit plan: Weekly, Monthly, or Yearly (Resident Step 3)
  final PermitPlanModel? selectedPermitPlan;

  // Vehicle Information (Resident Step 4)

  /// Vehicle plate number
  final String? plateNumber;

  /// Vehicle make (e.g., Toyota, Honda)
  final String? vehicleMake;

  /// Vehicle model (e.g., Camry, Civic)
  final String? vehicleModel;

  /// Vehicle color
  final String? vehicleColor;

  /// Vehicle year (e.g., 2020, 2021)
  final String? vehicleYear;

  // Document Paths (Resident Steps 5-7)

  /// Path to driving license image (Resident Step 5)
  final String? licenseImagePath;

  /// Path to vehicle registration image (Resident Step 6)
  final String? registrationImagePath;

  /// Path to insurance file - can be image or PDF (Resident Step 7)
  final String? insuranceFilePath;

  /// Flag indicating if insurance file is an image (true) or PDF (false)
  final bool? insuranceIsImage;

  // ==================== Visitor Info ====================
  // TODO: Add visitor-specific fields when visitor flow is implemented
  // Examples:
  // - Host resident name
  // - Visit date/time
  // - Visit duration
  // - Visit purpose

  /// Creates an instance of [OnboardingDataModel]
  const OnboardingDataModel({
    this.firstName,
    this.lastName,
    this.userType,
    this.selectedCommunity,
    this.unitNumber,
    this.buildingNumber,
    this.selectedPermitPlan,
    this.plateNumber,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleYear,
    this.licenseImagePath,
    this.registrationImagePath,
    this.insuranceFilePath,
    this.insuranceIsImage,
  });

  /// Creates an empty instance with all fields set to null
  factory OnboardingDataModel.empty() {
    return const OnboardingDataModel();
  }

  /// Creates a copy of this model with the given fields replaced with new values
  OnboardingDataModel copyWith({
    String? firstName,
    String? lastName,
    UserType? userType,
    String? selectedCommunity,
    String? unitNumber,
    String? buildingNumber,
    PermitPlanModel? selectedPermitPlan,
    String? plateNumber,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleYear,
    String? licenseImagePath,
    String? registrationImagePath,
    String? insuranceFilePath,
    bool? insuranceIsImage,
  }) {
    return OnboardingDataModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userType: userType ?? this.userType,
      selectedCommunity: selectedCommunity ?? this.selectedCommunity,
      unitNumber: unitNumber ?? this.unitNumber,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      selectedPermitPlan: selectedPermitPlan ?? this.selectedPermitPlan,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      licenseImagePath: licenseImagePath ?? this.licenseImagePath,
      registrationImagePath:
          registrationImagePath ?? this.registrationImagePath,
      insuranceFilePath: insuranceFilePath ?? this.insuranceFilePath,
      insuranceIsImage: insuranceIsImage ?? this.insuranceIsImage,
    );
  }

  /// Returns the user's full name (firstName + lastName)
  String? get fullName {
    if (firstName == null && lastName == null) return null;
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  /// Returns the permit expiration date based on the selected plan
  /// - Weekly: Today + 7 days
  /// - Monthly: Today + 30 days
  /// - Yearly: Today + 365 days
  DateTime? get permitExpirationDate {
    if (selectedPermitPlan == null) return null;

    final now = DateTime.now();
    final planValue = selectedPermitPlan!.value;

    if (planValue == 'weekly') {
      return now.add(const Duration(days: 7));
    } else if (planValue == 'monthly') {
      return now.add(const Duration(days: 30));
    } else if (planValue == 'yearly') {
      return now.add(const Duration(days: 365));
    }

    return null;
  }

  /// Returns formatted expiration date string (e.g., "20/10/2025")
  String? get formattedExpirationDate {
    final date = permitExpirationDate;
    if (date == null) return null;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  /// Checks if general onboarding (Steps 1-2) is complete
  bool get isGeneralOnboardingComplete {
    return firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty &&
        userType != null;
  }

  /// Checks if resident onboarding is complete (all 7 steps)
  bool get isResidentOnboardingComplete {
    if (!isGeneralOnboardingComplete || userType != UserType.resident) {
      return false;
    }

    return selectedCommunity != null &&
        selectedCommunity!.isNotEmpty &&
        unitNumber != null &&
        unitNumber!.isNotEmpty &&
        buildingNumber != null &&
        buildingNumber!.isNotEmpty &&
        selectedPermitPlan != null &&
        plateNumber != null &&
        plateNumber!.isNotEmpty &&
        vehicleMake != null &&
        vehicleMake!.isNotEmpty &&
        vehicleModel != null &&
        vehicleModel!.isNotEmpty &&
        vehicleColor != null &&
        vehicleColor!.isNotEmpty &&
        vehicleYear != null &&
        vehicleYear!.isNotEmpty &&
        licenseImagePath != null &&
        licenseImagePath!.isNotEmpty &&
        registrationImagePath != null &&
        registrationImagePath!.isNotEmpty &&
        insuranceFilePath != null &&
        insuranceFilePath!.isNotEmpty;
  }

  /// Checks if visitor onboarding is complete
  /// TODO: Implement when visitor flow is added
  bool get isVisitorOnboardingComplete {
    if (!isGeneralOnboardingComplete || userType != UserType.visitor) {
      return false;
    }
    // TODO: Add visitor-specific validation
    return false;
  }

  /// Checks if the entire onboarding flow is complete
  bool get isOnboardingComplete {
    if (userType == UserType.resident) {
      return isResidentOnboardingComplete;
    } else if (userType == UserType.visitor) {
      return isVisitorOnboardingComplete;
    }
    return false;
  }

  /// Converts the model to a Map for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType?.value,
      'selected_community': selectedCommunity,
      'unit_number': unitNumber,
      'building_number': buildingNumber,
      'permit_plan_type': selectedPermitPlan?.value,
      'plate_number': plateNumber,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_color': vehicleColor,
      'vehicle_year': vehicleYear,
      'license_image_path': licenseImagePath,
      'registration_image_path': registrationImagePath,
      'insurance_file_path': insuranceFilePath,
      'insurance_is_image': insuranceIsImage,
    };
  }

  /// Creates an instance from a Map (e.g., from Supabase)
  factory OnboardingDataModel.fromJson(Map<String, dynamic> json) {
    return OnboardingDataModel(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      userType: (json['user_type'] as String?)?.toUserType(),
      selectedCommunity: json['selected_community'] as String?,
      unitNumber: json['unit_number'] as String?,
      buildingNumber: json['building_number'] as String?,
      selectedPermitPlan: json['permit_plan_type'] != null
          ? PermitPlanModel.availablePlans.firstWhere(
              (plan) => plan.value == json['permit_plan_type'],
              orElse: () => PermitPlanModel.availablePlans.first,
            )
          : null,
      plateNumber: json['plate_number'] as String?,
      vehicleMake: json['vehicle_make'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleColor: json['vehicle_color'] as String?,
      vehicleYear: json['vehicle_year'] as String?,
      licenseImagePath: json['license_image_path'] as String?,
      registrationImagePath: json['registration_image_path'] as String?,
      insuranceFilePath: json['insurance_file_path'] as String?,
      insuranceIsImage: json['insurance_is_image'] as bool?,
    );
  }

  @override
  String toString() {
    return 'OnboardingDataModel('
        'firstName: $firstName, '
        'lastName: $lastName, '
        'userType: $userType, '
        'selectedCommunity: $selectedCommunity, '
        'unitNumber: $unitNumber, '
        'buildingNumber: $buildingNumber, '
        'selectedPermitPlan: $selectedPermitPlan, '
        'plateNumber: $plateNumber, '
        'vehicleMake: $vehicleMake, '
        'vehicleModel: $vehicleModel, '
        'vehicleColor: $vehicleColor, '
        'vehicleYear: $vehicleYear, '
        'licenseImagePath: $licenseImagePath, '
        'registrationImagePath: $registrationImagePath, '
        'insuranceFilePath: $insuranceFilePath, '
        'insuranceIsImage: $insuranceIsImage'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingDataModel &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.userType == userType &&
        other.selectedCommunity == selectedCommunity &&
        other.unitNumber == unitNumber &&
        other.buildingNumber == buildingNumber &&
        other.selectedPermitPlan == selectedPermitPlan &&
        other.plateNumber == plateNumber &&
        other.vehicleMake == vehicleMake &&
        other.vehicleModel == vehicleModel &&
        other.vehicleColor == vehicleColor &&
        other.vehicleYear == vehicleYear &&
        other.licenseImagePath == licenseImagePath &&
        other.registrationImagePath == registrationImagePath &&
        other.insuranceFilePath == insuranceFilePath &&
        other.insuranceIsImage == insuranceIsImage;
  }

  @override
  int get hashCode {
    return Object.hash(
      firstName,
      lastName,
      userType,
      selectedCommunity,
      unitNumber,
      buildingNumber,
      selectedPermitPlan,
      plateNumber,
      vehicleMake,
      vehicleModel,
      vehicleColor,
      vehicleYear,
      licenseImagePath,
      registrationImagePath,
      insuranceFilePath,
      insuranceIsImage,
    );
  }
}
