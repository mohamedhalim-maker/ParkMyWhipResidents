class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'user',
        isActive: json['is_active'] as bool? ?? true,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role,
        'is_active': isActive,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // Helper getters
  String get displayName => fullName.isNotEmpty ? fullName : email;

  bool get isAdmin => role == 'admin';
  
  bool get isResident => role == 'user' || role == 'resident';

  // Placeholder methods for auth_manager compatibility
  Future<void> sendEmailVerification() async {
    // TODO: Implement email verification when needed
  }

  Future<void> refreshUser() async {
    // TODO: Implement user refresh when needed
  }
}
