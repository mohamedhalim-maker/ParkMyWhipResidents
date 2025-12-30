/// Validators for onboarding form fields.
///
/// Provides validation methods for:
/// - Name fields (first name, last name)
/// - Phone number
/// - Address fields
/// - Vehicle information
/// - License plate format
class OnboardingValidators {
  /// Validate first name or last name
  /// Returns error message if invalid, null if valid
  ///
  /// Rules:
  /// - Cannot be empty
  /// - Minimum 2 characters
  /// - Letters only (allows spaces, hyphens, apostrophes for names like O'Brien, Mary-Jane)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'You need to fill this field';
    }

    final trimmedValue = value.trim();

    // Check minimum length
    if (trimmedValue.length < 2) {
      return 'Name must be at least 2 characters';
    }

    // Allow letters, spaces, hyphens, and apostrophes
    final validCharacters = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!validCharacters.hasMatch(trimmedValue)) {
      return 'Name should only contain letters';
    }

    return null;
  }

  /// Validate number fields (unit number, building number, etc.)
  /// Returns error message if invalid, null if valid
  ///
  /// Rules:
  /// - Cannot be empty
  /// - Must contain only digits (0-9)
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'This field cannot be empty';
    }

    final trimmedValue = value.trim();

    // Check if contains only digits
    final onlyDigits = RegExp(r'^[0-9]+$');
    if (!onlyDigits.hasMatch(trimmedValue)) {
      return 'Only numbers are allowed';
    }

    return null;
  }

  /// Validate unit number or building number (alphanumeric)
  /// Returns error message if invalid, null if valid
  ///
  /// Rules:
  /// - Cannot be empty
  /// - Alphanumeric characters only (letters, numbers, hyphens)
  /// - Examples: "12B", "A-5", "101", "Building 3"
  static String? validateUnitNumber(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'This field cannot be empty';
    }

    final trimmedValue = value.trim();

    // Allow alphanumeric characters, spaces, and hyphens
    final alphanumeric = RegExp(r'^[a-zA-Z0-9\s\-]+$');
    if (!alphanumeric.hasMatch(trimmedValue)) {
      return 'Only letters, numbers, and hyphens allowed';
    }

    return null;
  }

  /// Validate UK plate number
  /// Returns error message if invalid, null if valid
  ///
  /// Rules:
  /// - Cannot be empty
  /// - Alphanumeric characters only
  /// - Length between 2-8 characters
  static String? validatePlateNumber(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Plate number is required';
    }

    final trimmedValue = value.trim().toUpperCase();

    // Check length (UK plates are typically 2-8 characters)
    if (trimmedValue.length < 2 || trimmedValue.length > 8) {
      return 'Plate number must be 2-8 characters';
    }

    // Allow alphanumeric characters only (letters and numbers)
    final alphanumeric = RegExp(r'^[A-Z0-9]+$');
    if (!alphanumeric.hasMatch(trimmedValue)) {
      return 'Only letters and numbers allowed';
    }

    return null;
  }

  /// Validate vehicle make or model
  /// Returns error message if invalid, null if valid
  ///
  /// Rules:
  /// - Cannot be empty
  /// - Minimum 2 characters
  static String? validateVehicleField(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'This field is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Must be at least 2 characters';
    }

    return null;
  }

  /// Validate vehicle color
  /// Returns error message if invalid, null if valid
  ///
  /// Rules:
  /// - Cannot be empty
  /// - Minimum 3 characters
  /// - Letters only
  static String? validateVehicleColor(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Color is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 3) {
      return 'Must be at least 3 characters';
    }

    // Allow letters, spaces, and hyphens for compound colors (e.g., "Dark Blue")
    final validCharacters = RegExp(r"^[a-zA-Z\s\-]+$");
    if (!validCharacters.hasMatch(trimmedValue)) {
      return 'Only letters allowed';
    }

    return null;
  }

  /// Validate vehicle year
  /// Returns error message if invalid, null if valid
  /// /// Rules:
  /// - Cannot be empty
  /// - Must be a number between 1980 and current year
  static String? validateVehicleYear(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Year is required';
    }

    final trimmedValue = value.trim();

    // Check if numeric
    final year = int.tryParse(trimmedValue);
    if (year == null) {
      return 'Year must be a number';
    }

    final currentYear = DateTime.now().year;

    if (year < 1980 || year > currentYear) {
      return 'Year must be between 1980 and $currentYear';
    }

    return null;
  }
}
