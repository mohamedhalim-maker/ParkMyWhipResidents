import 'package:park_my_whip_residents/src/features/onboarding/data/models/onboarding_data_model.dart';

/// Service for managing onboarding data operations.
///
/// Handles:
/// - Saving onboarding data to Supabase (users table)
/// - Checking onboarding completion status
/// - Updating user profile with collected information
class OnboardingService {
  static const String _usersTable = 'users';

  /// Save onboarding data to the database
  /// Updates the user record with all collected information
  /// and sets onboarding_completed flag to true
  Future<void> saveOnboardingData({
    required String userId,
    required OnboardingData data,
  }) async {
    // TODO: Implement saveOnboardingData
    // 1. Update users table with onboarding data
    // 2. Set onboarding_completed = true
    // 3. Handle errors appropriately
    throw UnimplementedError();
  }

  /// Check if user has completed onboarding
  Future<bool> isOnboardingCompleted(String userId) async {
    // TODO: Implement isOnboardingCompleted
    // Query users table for onboarding_completed flag
    throw UnimplementedError();
  }

  /// Get existing onboarding data (for resume/edit)
  Future<OnboardingData?> getOnboardingData(String userId) async {
    // TODO: Implement getOnboardingData
    // Fetch user data from users table
    throw UnimplementedError();
  }
}
