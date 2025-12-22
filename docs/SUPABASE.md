# Supabase Integration Documentation

## Overview

This app uses Supabase for:
- **Authentication**: Email/password login, signup, password reset
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Multi-App Architecture**: Users can belong to multiple apps

---

## Database Schema

### Core Tables

```sql
-- Apps table (registry of all apps)
CREATE TABLE apps (
  id text PRIMARY KEY,                    -- e.g., 'park_my_whip_resident'
  name text NOT NULL,                     -- e.g., 'Park My Whip - Resident'
  description text,
  is_active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Users table (core user data)
CREATE TABLE users (
  id uuid PRIMARY KEY,                    -- Links to auth.users.id
  email text NOT NULL UNIQUE,
  full_name text NOT NULL,
  phone text,
  avatar_url text,
  is_active boolean DEFAULT true,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- User-Apps junction table (many-to-many)
CREATE TABLE user_apps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  app_id text REFERENCES apps(id) ON DELETE CASCADE,
  role text DEFAULT 'user',               -- 'user', 'admin', etc.
  is_active boolean DEFAULT true,
  app_specific_data jsonb DEFAULT '{}',   -- App-specific settings
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, app_id)                 -- One registration per app
);
```

### Relationship Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│    apps     │         │  user_apps  │         │    users    │
├─────────────┤         ├─────────────┤         ├─────────────┤
│ id (PK)     │◄────────│ app_id (FK) │         │ id (PK)     │
│ name        │         │ user_id (FK)│────────►│ email       │
│ description │         │ role        │         │ full_name   │
│ is_active   │         │ is_active   │         │ is_active   │
│ metadata    │         │ app_data    │         │ metadata    │
└─────────────┘         └─────────────┘         └─────────────┘
```

---

## Multi-App Architecture

### How It Works

1. **User signs up** → Record created in `users` table
2. **Register for app** → Record created in `user_apps` with `app_id`
3. **User logs in** → App checks `user_apps` for this `app_id`
4. **Role check** → Role comes from `user_apps.role`, not `users.role`

### App Configuration

**File**: `lib/src/core/constants/app_config.dart`

```dart
class AppConfig {
  static const String appId = 'park_my_whip_resident';
  static const String appName = 'Park My Whip - Resident';
}
```

### Sign-In Flow with App Check

```dart
Future<User?> signInWithEmail(...) async {
  // 1. Authenticate
  final response = await SupabaseConfig.auth.signInWithPassword(
    email: email,
    password: password,
  );

  // 2. Check if user is registered for THIS app
  final userApp = await _getUserAppRegistration(response.user!.id);
  if (userApp == null) {
    await SupabaseConfig.auth.signOut();
    throw Exception('Your account is not registered for this app.');
  }

  // 3. Check if user is active in this app
  if (!userApp.isActive) {
    await SupabaseConfig.auth.signOut();
    throw Exception('Your account has been deactivated.');
  }

  // 4. Fetch full user profile with app registration
  final user = await _getUserProfile(response.user!.id, userApp: userApp);
  return user;
}
```

### Query for User with App Registration

```dart
Future<UserApp?> _getUserAppRegistration(String userId) async {
  final response = await SupabaseConfig.client
      .from('user_apps')
      .select()
      .eq('user_id', userId)
      .eq('app_id', AppConfig.appId)
      .maybeSingle();

  if (response == null) return null;
  return UserApp.fromJson(response);
}
```

---

## Supabase Configuration

**File**: `lib/supabase/supabase_config.dart`

```dart
class SupabaseConfig {
  static late final SupabaseClient _client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client => _client;
  static GoTrueClient get auth => _client.auth;
}
```

---

## Common Queries

### Fetch User with App Registration

```dart
final response = await SupabaseConfig.client
    .from('users')
    .select('*, user_apps!inner(*)')
    .eq('id', userId)
    .eq('user_apps.app_id', AppConfig.appId)
    .single();
```

### Create User + App Registration (Signup)

```dart
// 1. Create user record
await SupabaseConfig.client.from('users').insert({
  'id': authUser.id,
  'email': email,
  'full_name': fullName,
});

// 2. Register for this app
await SupabaseConfig.client.from('user_apps').insert({
  'user_id': authUser.id,
  'app_id': AppConfig.appId,
  'role': 'user',
  'is_active': true,
});
```

### Check if User Exists in App

```dart
final exists = await SupabaseConfig.client
    .from('user_apps')
    .select('id')
    .eq('user_id', userId)
    .eq('app_id', AppConfig.appId)
    .maybeSingle();

return exists != null;
```

---

## Row Level Security (RLS)

### Users Table Policies

```sql
-- Users can read their own data
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);
```

### User Apps Table Policies

```sql
-- Users can read their own app registrations
CREATE POLICY "Users can view own app registrations"
  ON user_apps FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can manage all (for signup)
-- Use service_role key for signup operations
```

---

## Authentication Methods

### Email/Password Sign In

```dart
final response = await SupabaseConfig.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### Email/Password Sign Up

```dart
final response = await SupabaseConfig.auth.signUp(
  email: email,
  password: password,
  emailRedirectTo: '${AppConfig.deepLinkScheme}://verify',
);
```

### Password Reset Email

```dart
await SupabaseConfig.auth.resetPasswordForEmail(
  email,
  redirectTo: '${AppConfig.deepLinkScheme}://reset-password',
);
```

### Update Password

```dart
await SupabaseConfig.auth.updateUser(
  UserAttributes(password: newPassword),
);
```

### Sign Out

```dart
await SupabaseConfig.auth.signOut();
```

### Get Current Session

```dart
final session = SupabaseConfig.auth.currentSession;
final user = SupabaseConfig.auth.currentUser;
```

### Listen to Auth Changes

```dart
SupabaseConfig.auth.onAuthStateChange.listen((data) {
  final event = data.event;
  final session = data.session;
  
  switch (event) {
    case AuthChangeEvent.signedIn:
      // Handle sign in
      break;
    case AuthChangeEvent.signedOut:
      // Handle sign out
      break;
    case AuthChangeEvent.passwordRecovery:
      // Handle password reset link clicked
      break;
  }
});
```

---

## Deep Links

### Configuration

**File**: `lib/src/core/constants/app_config.dart`

```dart
static const String deepLinkScheme = 'parkmywhip-resident';
```

### URL Patterns

| Action | URL |
|--------|-----|
| Email Verification | `parkmywhip-resident://verify` |
| Password Reset | `parkmywhip-resident://reset-password` |

### Handling Deep Links

**File**: `lib/src/core/services/deep_link_service.dart`

```dart
class DeepLinkService {
  void handleDeepLink(Uri uri) {
    if (uri.path.contains('reset-password')) {
      // Navigate to reset password page
      Navigator.pushNamed(context, RoutesName.resetPassword);
    }
  }
}
```

---

## Error Handling

All Supabase errors are handled by `NetworkExceptions`:

```dart
try {
  await someSupabaseOperation();
} catch (e) {
  // Get user-friendly message
  final message = NetworkExceptions.getSupabaseExceptionMessage(e);
  
  // Or show dialog
  NetworkExceptions.showErrorDialog(e);
}
```

### Common Supabase Errors

| Error | User Message |
|-------|--------------|
| `invalid_credentials` | "Invalid email or password" |
| `email_not_confirmed` | "Please verify your email address" |
| `user_already_exists` | "This email is already registered" |
| `42501` | "Permission denied (RLS policy)" |
| `23505` | "Record already exists" |
