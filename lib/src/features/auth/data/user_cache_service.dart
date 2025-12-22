import 'dart:developer';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/core/models/user_model.dart';
import 'package:park_my_whip_residents/src/features/auth/data/auth_constants.dart';

/// Service responsible for caching user data locally
/// Uses SharedPreferences to persist user information across app sessions
class UserCacheService {
  final SharedPrefHelper _sharedPrefHelper;

  const UserCacheService(this._sharedPrefHelper);

  /// Saves user data to local cache
  Future<void> cacheUser(User user) async {
    try {
      await _sharedPrefHelper.saveObject(
        AuthConstants.userProfileCacheKey,
        user.toJson(),
      );
      await _sharedPrefHelper.saveString(
        AuthConstants.userIdCacheKey,
        user.id,
      );
      log('User cached successfully', name: AuthConstants.loggerName);
    } catch (e) {
      log('Failed to cache user: $e', name: AuthConstants.loggerName, error: e);
      // Don't rethrow - caching failure shouldn't break auth flow
    }
  }

  /// Retrieves cached user data from local storage
  Future<User?> getCachedUser() async {
    try {
      final userData = await _sharedPrefHelper.getObject(
        AuthConstants.userProfileCacheKey,
      );
      if (userData != null) {
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      log('Failed to retrieve cached user: $e',
          name: AuthConstants.loggerName, error: e);
      return null;
    }
  }

  /// Retrieves cached user ID
  Future<String?> getCachedUserId() async {
    try {
      return await _sharedPrefHelper.getString(
        AuthConstants.userIdCacheKey,
      );
    } catch (e) {
      log('Failed to retrieve cached user ID: $e',
          name: AuthConstants.loggerName, error: e);
      return null;
    }
  }

  /// Clears all cached user data
  Future<void> clearCache() async {
    try {
      await _sharedPrefHelper.remove(AuthConstants.userProfileCacheKey);
      await _sharedPrefHelper.remove(AuthConstants.userIdCacheKey);
      log('User cache cleared successfully', name: AuthConstants.loggerName);
    } catch (e) {
      log('Failed to clear user cache: $e',
          name: AuthConstants.loggerName, error: e);
      // Don't rethrow - cache clearing failure shouldn't break sign out
    }
  }

  /// Checks if user data is cached
  Future<bool> hasCache() async {
    final userId = await getCachedUserId();
    return userId != null;
  }
}
