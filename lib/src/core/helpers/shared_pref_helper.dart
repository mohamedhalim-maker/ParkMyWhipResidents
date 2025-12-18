import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SharedPrefHelper {
  Future<void> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error saving string to SharedPreferences: $e');
    }
  }

  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('Error getting string from SharedPreferences: $e');
      return null;
    }
  }

  Future<void> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving bool to SharedPreferences: $e');
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e) {
      debugPrint('Error getting bool from SharedPreferences: $e');
      return null;
    }
  }

  Future<void> saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (e) {
      debugPrint('Error saving int to SharedPreferences: $e');
    }
  }

  Future<int?> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      debugPrint('Error getting int from SharedPreferences: $e');
      return null;
    }
  }

  Future<void> saveObject(String key, Map<String, dynamic> object) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(object);
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error saving object to SharedPreferences: $e');
    }
  }

  Future<Map<String, dynamic>?> getObject(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting object from SharedPreferences: $e');
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error removing key from SharedPreferences: $e');
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
    }
  }
}
