import 'dart:developer';
import 'package:park_my_whip_residents/src/core/models/supabase_user_model.dart';
import 'package:park_my_whip_residents/src/core/networking/network_exceptions.dart';
import 'package:park_my_whip_residents/src/core/services/supabase_user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<SupabaseUserModel> signIn(String email, String password);
  Future<SupabaseUserModel> signUp(String email, String password);
  Future<void> signOut();
  Future<void> verifyOTP(String email, String token);
  Future<void> resendOTP(String email);
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
}

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  SupabaseAuthRemoteDataSource({required this.supabaseUserService});

  final SupabaseUserService supabaseUserService;
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<SupabaseUserModel> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        log('Sign in failed: No user returned', name: 'AuthRemoteDataSource', level: 900);
        throw Exception('Login failed. Please try again.');
      }

      log('Sign in successful for: $email', name: 'AuthRemoteDataSource');
      
      // Fetch and cache user profile
      final user = await supabaseUserService.getCurrentUser();
      
      if (user == null) {
        log('Failed to fetch user profile', name: 'AuthRemoteDataSource', level: 900);
        throw Exception('Failed to retrieve user profile. Please try again.');
      }
      
      return user;
    } catch (e) {
      log('Error during sign in: $e', name: 'AuthRemoteDataSource', level: 900);
      final errorMessage = NetworkExceptions.getSupabaseExceptionMessage(e);
      throw Exception(errorMessage);
    }
  }

  @override
  Future<SupabaseUserModel> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
      );
      
      if (response.user == null) {
        log('Sign up failed: No user returned', name: 'AuthRemoteDataSource', level: 900);
        throw Exception('Sign up failed. Please try again.');
      }

      log('Sign up successful for: $email', name: 'AuthRemoteDataSource');
      
      // Fetch and cache user profile
      final user = await supabaseUserService.getCurrentUser();
      
      if (user == null) {
        log('Failed to fetch user profile', name: 'AuthRemoteDataSource', level: 900);
        throw Exception('Failed to retrieve user profile. Please try again.');
      }
      
      return user;
    } catch (e) {
      log('Error during sign up: $e', name: 'AuthRemoteDataSource', level: 900);
      final errorMessage = NetworkExceptions.getSupabaseExceptionMessage(e);
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await supabaseUserService.clearCache();
      log('Sign out successful', name: 'AuthRemoteDataSource');
    } catch (e) {
      log('Error during sign out: $e', name: 'AuthRemoteDataSource', level: 900);
      final errorMessage = NetworkExceptions.getSupabaseExceptionMessage(e);
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> verifyOTP(String email, String token) async {
    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: token,
      );
      log('OTP verification successful for: $email', name: 'AuthRemoteDataSource');
    } catch (e) {
      log('Error during OTP verification: $e', name: 'AuthRemoteDataSource', level: 900);
      final errorMessage = NetworkExceptions.getSupabaseExceptionMessage(e);
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> resendOTP(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      log('OTP resent successfully to: $email', name: 'AuthRemoteDataSource');
    } catch (e) {
      log('Error resending OTP: $e', name: 'AuthRemoteDataSource', level: 900);
      final errorMessage = NetworkExceptions.getSupabaseExceptionMessage(e);
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'parkmywhip-resident://reset-password',
      );
      log('Password reset email sent to: $email', name: 'AuthRemoteDataSource');
    } catch (e) {
      log('Error sending password reset: $e', name: 'AuthRemoteDataSource', level: 900);
      final errorMessage = NetworkExceptions.getSupabaseExceptionMessage(e);
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      log('Password updated successfully', name: 'AuthRemoteDataSource');
    } catch (e) {
      log('Error updating password: $e', name: 'AuthRemoteDataSource', level: 900);
      final errorMessage = NetworkExceptions.getSupabaseExceptionMessage(e);
      throw Exception(errorMessage);
    }
  }
}
