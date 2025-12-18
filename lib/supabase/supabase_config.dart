import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    // Prevent double initialization
    if (_isInitialized) {
      debugPrint('Supabase already initialized');
      return;
    }
    
    try {
      // Supabase is automatically initialized by Dreamflow when connected via the Supabase panel
      // Check if Dreamflow has already initialized it
      final client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('Supabase instance found (initialized by Dreamflow)');
      return;
    } catch (e) {
      debugPrint('Supabase not initialized by Dreamflow, attempting manual initialization');
    }
    
    // Manual initialization fallback
    // Get environment variables or use placeholders
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('Supabase initialized manually');
    } else {
      debugPrint('Warning: Supabase credentials not found. Please connect via Supabase panel in Dreamflow.');
    }
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}

/// Generic CRUD Operations Service for Supabase
class SupabaseService {
  SupabaseClient get _client => SupabaseConfig.client;

  /// Create a new record
  Future<Map<String, dynamic>?> create({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      debugPrint('Error creating record in $table: $e');
      rethrow;
    }
  }

  /// Read records with optional filters
  Future<List<Map<String, dynamic>>> read({
    required String table,
    String? column,
    dynamic value,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = _client.from(table).select();
      
      if (column != null && value != null) {
        query = query.eq(column, value);
      }
      
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query as List<dynamic>;
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error reading from $table: $e');
      rethrow;
    }
  }

  /// Read a single record by ID
  Future<Map<String, dynamic>?> readById({
    required String table,
    required String id,
  }) async {
    try {
      final response = await _client.from(table).select().eq('id', id).single();
      return response;
    } catch (e) {
      debugPrint('Error reading record from $table: $e');
      rethrow;
    }
  }

  /// Update a record
  Future<Map<String, dynamic>?> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.from(table).update(data).eq('id', id).select().single();
      return response;
    } catch (e) {
      debugPrint('Error updating record in $table: $e');
      rethrow;
    }
  }

  /// Delete a record
  Future<void> delete({
    required String table,
    required String id,
  }) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting record from $table: $e');
      rethrow;
    }
  }

  /// Stream records with optional filters
  Stream<List<Map<String, dynamic>>> stream({
    required String table,
    String? column,
    dynamic value,
  }) {
    try {
      return _client.from(table).stream(primaryKey: ['id']).map((data) {
        if (column != null && value != null) {
          return data.where((item) => item[column] == value).toList();
        }
        return data;
      });
    } catch (e) {
      debugPrint('Error streaming from $table: $e');
      rethrow;
    }
  }

  /// Custom query execution
  Future<List<Map<String, dynamic>>> query({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = _client.from(table).select(select ?? '*');
      
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query as List<dynamic>;
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error executing query on $table: $e');
      rethrow;
    }
  }
}
