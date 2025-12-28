import 'package:park_my_whip_residents/src/core/models/user_app_model.dart';

class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The user's registration for the current app (from user_apps junction table)
  final UserApp? userApp;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.userApp,
  });

  factory User.fromJson(Map<String, dynamic> json, {UserApp? userApp}) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        userApp: userApp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'is_active': isActive,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (userApp != null) 'user_app': userApp!.toJson(),
      };

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserApp? userApp,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isActive: isActive ?? this.isActive,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        userApp: userApp ?? this.userApp,
      );

  // Helper getters
  String get displayName => fullName.isNotEmpty ? fullName : email;

  /// Get the user's role for the current app (from userApp)
  String get role => userApp?.role ?? 'user';

  bool get isAdmin => role == 'admin';

  bool get isResident => role == 'user' || role == 'resident';

  /// Whether the user is registered for the current app
  bool get isRegisteredForApp => userApp != null;

  /// Whether the user is active in the current app
  bool get isActiveInApp => userApp?.isActive ?? false;
}
