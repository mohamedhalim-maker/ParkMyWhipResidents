/// Model representing a user's registration with a specific app
/// Maps to the `user_apps` junction table in Supabase
class UserApp {
  final String id;
  final String userId;
  final String appId;
  final String role;
  final bool isActive;
  final Map<String, dynamic> appSpecificData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserApp({
    required this.id,
    required this.userId,
    required this.appId,
    required this.role,
    required this.isActive,
    required this.appSpecificData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserApp.fromJson(Map<String, dynamic> json) => UserApp(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        appId: json['app_id'] as String,
        role: json['role'] as String? ?? 'user',
        isActive: json['is_active'] as bool? ?? true,
        appSpecificData:
            json['app_specific_data'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'app_id': appId,
        'role': role,
        'is_active': isActive,
        'app_specific_data': appSpecificData,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  UserApp copyWith({
    String? id,
    String? userId,
    String? appId,
    String? role,
    bool? isActive,
    Map<String, dynamic>? appSpecificData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserApp(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        appId: appId ?? this.appId,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        appSpecificData: appSpecificData ?? this.appSpecificData,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // Helper getters
  bool get isAdmin => role == 'admin';
  bool get isResident => role == 'user' || role == 'resident';
}
