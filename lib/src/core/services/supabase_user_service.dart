import 'dart:convert';
import 'dart:developer';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/helpers/shared_pref_helper.dart';
import 'package:park_my_whip_residents/src/core/models/supabase_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserService {
  SupabaseUserService({required this.sharedPrefHelper});

  final SharedPrefHelper sharedPrefHelper;
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> cacheUser(SupabaseUserModel user) async {
    try {
      await sharedPrefHelper.saveObject(SharedPrefStrings.userProfile, user.toJson());
      await sharedPrefHelper.saveString(SharedPrefStrings.userId, user.id);
      log('User cached successfully', name: 'SupabaseUserService');
    } catch (e) {
      log('Error caching user: $e', name: 'SupabaseUserService', level: 900);
    }
  }

  Future<SupabaseUserModel?> getCachedUser() async {
    try {
      final userJson = await sharedPrefHelper.getObject(SharedPrefStrings.userProfile);
      if (userJson != null) {
        return SupabaseUserModel.fromJson(userJson);
      }
      return null;
    } catch (e) {
      log('Error getting cached user: $e', name: 'SupabaseUserService', level: 900);
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await sharedPrefHelper.remove(SharedPrefStrings.userProfile);
      await sharedPrefHelper.remove(SharedPrefStrings.userId);
      log('User cache cleared', name: 'SupabaseUserService');
    } catch (e) {
      log('Error clearing cache: $e', name: 'SupabaseUserService', level: 900);
    }
  }

  Future<SupabaseUserModel?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();

      final user = SupabaseUserModel.fromJson(response);
      await cacheUser(user);
      return user;
    } catch (e) {
      log('Error getting current user: $e', name: 'SupabaseUserService', level: 900);
      return await getCachedUser();
    }
  }

  Future<void> createUserRecord(String userId, String email, {String? firstName, String? lastName}) async {
    try {
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'email_verified': false,
      });
      log('User record created successfully', name: 'SupabaseUserService');
    } catch (e) {
      log('Error creating user record: $e', name: 'SupabaseUserService', level: 900);
      rethrow;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) throw Exception('No active session');

      await _supabase
          .from('users')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', session.user.id);

      final updatedUser = await getCurrentUser();
      if (updatedUser != null) {
        await cacheUser(updatedUser);
      }
    } catch (e) {
      log('Error updating user profile: $e', name: 'SupabaseUserService', level: 900);
      rethrow;
    }
  }
}
