/// Enum representing the type of user in the onboarding flow
enum UserType {
  /// User is a resident
  resident,

  /// User is a visitor
  visitor,
}

/// Extension to provide display names for UserType
extension UserTypeExtension on UserType {
  /// Returns a user-friendly display name for the user type
  String get displayName {
    switch (this) {
      case UserType.resident:
        return 'Resident';
      case UserType.visitor:
        return 'Visitor';
    }
  }

  /// Returns the value as a string for storage/API calls
  String get value {
    switch (this) {
      case UserType.resident:
        return 'resident';
      case UserType.visitor:
        return 'visitor';
    }
  }
}

/// Extension to parse UserType from string
extension UserTypeParser on String {
  /// Converts a string to UserType enum
  UserType? toUserType() {
    switch (toLowerCase()) {
      case 'resident':
        return UserType.resident;
      case 'visitor':
        return UserType.visitor;
      default:
        return null;
    }
  }
}
