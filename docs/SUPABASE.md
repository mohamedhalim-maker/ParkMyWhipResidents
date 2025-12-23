# Supabase Integration Documentation

## Overview

This app uses Supabase for:
- **Authentication**: Email/password login, signup, password reset
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Multi-App Architecture**: Users can belong to multiple apps

---

## Password Recovery Flow

### Overview

The password recovery system handles the complete flow from requesting a password reset to completing it, with robust session management to prevent security issues.

### The Problem

When a user clicks a password reset link, Supabase creates a **temporary recovery session** (similar to login) that persists in local storage. If the user closes the app without completing the password reset, they could be auto-logged in to the dashboard with this temporary session on next app launch - a security risk.

### The Solution

We track recovery mode with a persistent flag in `SharedPreferences` that survives app restarts. The flag ensures abandoned recovery sessions are properly cleaned up.

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER REQUESTS PASSWORD RESET                                  │
│    ├─ User enters email on forgot password page                 │
│    ├─ ForgotPasswordCubit.validateEmailForm()                   │
│    ├─ AuthManager.resetPassword(email)                          │
│    └─ Supabase sends email with reset link                      │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. USER CLICKS RESET LINK (VALID TOKEN)                         │
│    ├─ App opens via deep link                                   │
│    ├─ DeepLinkErrorHandler checks for error params              │
│    │   └─ If error found → navigate to error page               │
│    ├─ Supabase validates token and creates recovery session     │
│    ├─ PASSWORD_RECOVERY auth event fires                        │
│    ├─ PasswordRecoveryManager.setRecoveryMode(true)             │
│    │   └─ Saves flag: is_recovery_mode = true                   │
│    └─ Navigate to ResetPasswordPage                             │
└─────────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────┴───────┐
                    │               │
        ┌───────────▼─────┐    ┌────▼──────────────┐
        │ 3A. USER        │    │ 3B. USER CLOSES   │
        │ COMPLETES RESET │    │ APP (ABANDONED)   │
        └───────────┬─────┘    └────┬──────────────┘
                    │               │
        ┌───────────▼─────┐    ┌────▼──────────────┐
        │ - Enter new     │    │ Flag remains TRUE │
        │   password      │    │ Session saved in  │
        │ - Call          │    │ local storage     │
        │   updatePassword│    └────┬──────────────┘
        │ - Set flag      │         │
        │   to FALSE      │    ┌────▼──────────────┐
        │ - User stays    │    │ 4. APP REOPENS    │
        │   logged in ✓   │    │                   │
        └─────────────────┘    │ Step 1: DI Setup  │
                               │ Step 2: Supabase  │
                               │   initialize()    │
                               │   └─ Restores     │
                               │      session      │
                               │ Step 3: Check     │
                               │   recovery flag   │
                               │   └─ Flag = TRUE  │
                               │   └─ Sign out!    │
                               │ Step 4: Run app   │
                               │ Step 5:           │
                               │   getInitialRoute │
                               │   └─ Flag = TRUE  │
                               │   └─ Route LOGIN  │
                               │ Step 6: Clear     │
                               │   flag to FALSE   │
                               └───────────────────┘
```

### Implementation Details

#### 1. Core Components

**PasswordRecoveryManager** (`lib/src/core/services/password_recovery_manager.dart`)
- Manages recovery mode flag in SharedPreferences
- Handles abandoned session cleanup
- Listens for PASSWORD_RECOVERY auth events
- Navigates to reset password page

**DeepLinkErrorHandler** (`lib/src/core/services/deep_link_error_handler.dart`)
- Intercepts deep links with error parameters
- Handles expired/invalid reset links
- Shows user-friendly error page

**SharedPrefHelper** (`lib/src/core/helpers/shared_pref_helper.dart`)
- Provides synchronous access to recovery flag via `getBoolSync()`
- Cache initialized at app startup for immediate flag checks

#### 2. Initialization Sequence

**Critical Order in `main.dart`:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Setup DI and initialize SharedPrefHelper cache
  await setupDependencyInjection();
  
  // Step 2: Initialize Supabase (restores any existing session)
  // CRITICAL: Must run BEFORE recovery check
  await SupabaseConfig.initialize();
  
  // Step 3: Check for abandoned recovery sessions
  // Signs out user if flag is TRUE (but doesn't clear flag yet)
  await PasswordRecoveryManager.checkAndClearAbandonedRecoverySession();
  
  // Step 4: Setup deep link error handler
  DeepLinkErrorHandler.setup();
  
  // Step 5: Setup auth listener for PASSWORD_RECOVERY events
  PasswordRecoveryManager.setupAuthListener();
  
  // Step 6: Run app (getInitialRoute will check flag)
  runApp(const ParkMyWhipResidentApp());
  
  // Step 7: Clear flag after routing decision is made
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await PasswordRecoveryManager.clearRecoveryFlagAfterRouting();
  });
}
```

**Why This Order Matters:**
1. Supabase must initialize BEFORE recovery check so session exists to sign out
2. Recovery check signs out but doesn't clear flag (for routing)
3. App runs and `getInitialRoute()` checks flag synchronously
4. Flag cleared AFTER routing decision to prevent race condition

#### 3. Routing Logic

**AppRouter.getInitialRoute()** checks flag synchronously:

```dart
static String getInitialRoute() {
  final helper = getIt<SharedPrefHelper>();
  final isRecoveryMode = helper.getBoolSync(SharedPrefStrings.isRecoveryMode) ?? false;
  final session = SupabaseConfig.auth.currentSession;

  // If recovery flag is TRUE, ALWAYS route to login
  // This prevents accessing dashboard with temporary recovery session
  if (isRecoveryMode) {
    return RoutesName.login;  // ✓ Safe
  }

  // Normal flow: check session
  if (session != null) {
    return RoutesName.dashboard;
  }

  return RoutesName.login;
}
```

#### 4. Flag Lifecycle

**Flag Storage Key:** `SharedPrefStrings.isRecoveryMode`

**When Set to TRUE:**
- PASSWORD_RECOVERY auth event fires (user clicked valid reset link)

**When Set to FALSE:**
- User completes password reset (in ForgotPasswordCubit)
- Post-frame callback after app startup (cleanup)

**Synchronous Access:**
```dart
// Instance method on SharedPrefHelper singleton
bool? isRecoveryMode = helper.getBoolSync(SharedPrefStrings.isRecoveryMode);
```

#### 5. Error Handling

**Invalid/Expired Links:**
- DeepLinkErrorHandler intercepts URLs with error parameters
- Common errors: `otp_expired`, `invalid_request`, `access_denied`
- User shown friendly error page instead of generic Supabase error

**Edge Cases Handled:**
- User closes app during reset → signed out on next launch
- Multiple reset requests → latest link invalidates previous
- Network errors → proper error messages shown
- Session restoration race conditions → flag checked synchronously

### Files Involved

```
lib/
├── main.dart                                    # Initialization sequence
├── src/
│   ├── core/
│   │   ├── config/
│   │   │   └── injection.dart                   # DI setup with SharedPrefHelper init
│   │   ├── constants/
│   │   │   └── strings.dart                     # SharedPrefStrings.isRecoveryMode
│   │   ├── helpers/
│   │   │   └── shared_pref_helper.dart          # Flag storage with sync access
│   │   ├── routes/
│   │   │   └── router.dart                      # getInitialRoute() flag check
│   │   └── services/
│   │       ├── deep_link_error_handler.dart     # Intercepts invalid links
│   │       └── password_recovery_manager.dart   # Recovery session management
│   └── features/
│       └── auth/
│           ├── data/
│           │   └── supabase_auth_manager.dart   # resetPassword(), updatePassword()
│           └── presentation/
│               ├── cubit/
│               │   └── forgot_password/
│               │       └── forgot_password_cubit.dart  # UI logic
│               └── pages/
│                   └── forgot_password_pages/
│                       ├── forgot_password_page.dart      # Enter email
│                       ├── reset_link_sent_page.dart      # Confirmation
│                       ├── reset_link_error_page.dart     # Error page
│                       ├── reset_password_page.dart       # Enter new password
│                       └── password_reset_success_page.dart  # Success
```

### Session Storage (Automatic)

Supabase Flutter SDK automatically handles session persistence:

**Storage Location:**
- Android/iOS: `SharedPreferences` (key: `supabase.auth.token`)
- Web: `localStorage`
- Desktop: Local storage files

**What's Stored:**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "v1.MRjNIb...",
  "expires_at": 1735123456,
  "user": { "id": "...", "email": "..." }
}
```

**Automatic Operations:**
- Sign in → Session saved
- Token refresh → Session updated
- Sign out → Session cleared
- App restart → Session restored in `Supabase.initialize()`

### Testing Checklist

1. ✅ **Normal Password Reset:**
   - Request reset → receive email → click link → enter new password → login with new password

2. ✅ **Abandoned Recovery Session:**
   - Request reset → click link → **close app immediately** → reopen app → should show LOGIN page (not dashboard)

3. ✅ **Expired Link:**
   - Request reset → wait for link to expire → click link → should show error page

4. ✅ **Invalid Link:**
   - Manually modify reset link parameters → click link → should show error page

5. ✅ **Multiple Reset Requests:**
   - Request reset → request again → first link should be invalidated

### Logging

All operations are logged using `AppLogger` with domain-specific channels:

```dart
AppLogger.auth('Recovery mode check - flag value: $isRecoveryMode');
AppLogger.navigation('Routing to login - recovery flag detected');
AppLogger.deepLink('Invalid link detected - showing error page');
AppLogger.error('Failed to clear recovery flag', error: e, stackTrace: st);
```

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
CREATE TABLE public.user_apps (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  app_id text NOT NULL,
  role text NOT NULL DEFAULT 'user'::text,
  is_active boolean NOT NULL DEFAULT true,
  metadata jsonb NULL DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_apps_pkey PRIMARY KEY (id),
  CONSTRAINT user_apps_user_id_app_id_key UNIQUE (user_id, app_id),
  CONSTRAINT user_apps_app_id_fkey FOREIGN KEY (app_id) REFERENCES apps (id) ON DELETE CASCADE,
  CONSTRAINT user_apps_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_apps_user_id ON public.user_apps USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_user_apps_app_id ON public.user_apps USING btree (app_id) TABLESPACE pg_default;
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

### PostgreSQL Functions (Bypass RLS)

Some operations need to bypass RLS (e.g., password reset when user is not authenticated). Use `SECURITY DEFINER` functions:

```sql
-- Combined function to get user by email WITH app access check
-- Used for password reset validation (more efficient than separate queries)
CREATE OR REPLACE FUNCTION public.get_user_by_email_with_app_check(
  user_email text,
  p_app_id text
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'user', row_to_json(u.*),
    'user_app', row_to_json(ua.*)
  ) INTO result
  FROM users u
  LEFT JOIN user_apps ua ON ua.user_id = u.id AND ua.app_id = p_app_id
  WHERE u.email = user_email;
  
  RETURN result;
END;
$$;

-- Grant execute permission to authenticated and anonymous users
GRANT EXECUTE ON FUNCTION public.get_user_by_email_with_app_check(text, text) TO authenticated, anon;
```

**Usage in Dart:**
```dart
final result = await SupabaseConfig.client.rpc(
  'get_user_by_email_with_app_check',
  params: {
    'user_email': email,
    'p_app_id': AppConfig.appId,
  },
);

if (result != null) {
  final data = Map<String, dynamic>.from(result as Map);
  final userData = data['user'] as Map<String, dynamic>?;
  final userAppData = data['user_app'] as Map<String, dynamic>?;
  
  // Check if user exists
  if (userData == null) {
    // User not found
  }
  
  // Check if user belongs to app
  if (userAppData == null) {
    // User not registered for this app
  }
}
```

**Why `SECURITY DEFINER` is needed:**
- RLS policies require `auth.uid()` to match the user's ID
- During password reset, user is NOT authenticated (`auth.uid()` is NULL)
- `SECURITY DEFINER` runs function with owner privileges, bypassing RLS
- Single query is more efficient than multiple separate queries
- Reduces database round-trips and ensures atomic data retrieval

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

**Important**: Password reset includes multi-app validation:

```dart
// Reset password with app-specific validation
await authManager.resetPassword(email: email);

// This performs the following checks:
// 1. Verifies user exists in users table
// 2. Checks if email is verified
// 3. Validates user belongs to current app (user_apps table)
// 4. Ensures user is active in the app
// 5. Only then sends reset link
```

**Implementation in SupabaseAuthManager**:

```dart
@override
Future<void> resetPassword({required String email}) async {
  // Get user and app data in ONE query using combined RPC function
  final result = await SupabaseConfig.client.rpc(
    'get_user_by_email_with_app_check',
    params: {
      'user_email': email,
      'p_app_id': AppConfig.appId,
    },
  );

  if (result == null) {
    throw Exception('No account found with this email address.');
  }

  final data = Map<String, dynamic>.from(result as Map);
  final userData = data['user'] as Map<String, dynamic>?;
  final userAppData = data['user_app'] as Map<String, dynamic>?;

  // 1. Check if user exists
  if (userData == null) {
    throw Exception('No account found with this email address.');
  }

  final userId = userData['id'] as String;

  // 2. Check if email is verified
  final isVerified = await _isUserEmailVerified(userId);
  if (!isVerified) {
    throw Exception('Your email is not verified. Please verify your email first.');
  }

  // 3. Check if user belongs to current app
  if (userAppData == null) {
    throw Exception('Your account is not registered for this app.');
  }

  // 4. Check if user is active
  if (!userApp.isActive) {
    throw Exception('Your account has been deactivated.');
  }

  // 5. Send reset email
  await SupabaseConfig.auth.resetPasswordForEmail(
    email,
    redirectTo: '${AppConfig.deepLinkScheme}://reset-password',
  );
}
```

**Why This Matters for Multi-App**:
- Prevents password resets for users who belong to different apps using the same Supabase instance
- Ensures only verified, active users can reset passwords
- Protects against account enumeration attacks

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

The app follows the **Official Supabase Pattern** for deep linking:

1. **Error Interception** (`DeepLinkErrorHandler`):
   - Intercepts deep links *before* Supabase processes them.
   - Checks for error parameters (e.g., `error=access_denied`, `error_code=otp_expired`).
   - If an error is found (e.g., expired link), it navigates directly to `RoutesName.resetLinkError`.

2. **Automatic Processing** (Supabase):
   - If no errors are found, Supabase automatically processes the link.
   - Validates the token with the backend.
   - Triggers an `AuthChangeEvent.passwordRecovery` event.

3. **Navigation** (`ParkMyWhipResidentApp`):
   - Listens to `onAuthStateChange`.
   - When `PASSWORD_RECOVERY` event is received, navigates to `RoutesName.resetPassword`.

**File**: `lib/src/core/services/deep_link_error_handler.dart`

```dart
class DeepLinkErrorHandler {
  static void setup() {
    _appLinks.uriLinkStream.listen((uri) {
      // Check for error parameters
      if (hasError) {
        // Navigate to error page
      }
    });
  }
}
```

**File**: `lib/park_my_whip_resident_app.dart`

```dart
SupabaseConfig.auth.onAuthStateChange.listen((data) {
  if (data.event == AuthChangeEvent.passwordRecovery) {
    // Navigate to reset password page
  }
});
```

---

## Error Handling

All Supabase errors are handled by `NetworkExceptions`, which automatically extracts clean, user-friendly messages:

```dart
try {
  await someSupabaseOperation();
} catch (e) {
  // Get user-friendly message (technical details removed)
  final message = NetworkExceptions.getSupabaseExceptionMessage(e);
  
  // Or show dialog
  NetworkExceptions.showErrorDialog(e);
}
```

### Error Message Extraction

`NetworkExceptions` automatically cleans error messages by:
- Removing class names and constructors
- Extracting the actual error message
- Removing code, details, and hint fields
- Providing context-specific user-friendly messages

**Example:**
```dart
// Raw error from Supabase:
PostgrestException (PostgrestException(
  message: Could not find the 'app_specific_data' column of 'user_apps' in the schema cache, 
  code: PGRST204, 
  details: Bad Request, 
  hint: null
))

// Cleaned message shown to user:
"Database schema error. Please ensure your database structure is up to date."
```

### Common Supabase Errors

| Error Type | Code/Pattern | User Message |
|------------|--------------|--------------|
| Auth | `invalid_credentials` | "Invalid email or password" |
| Auth | `email_not_confirmed` | "Please verify your email address" |
| Auth | `user_already_exists` | "This email is already registered" |
| Auth | `over_email_send_rate_limit` | "Too many emails sent. Please wait..." |
| Database | `42501` | "Permission denied (RLS policy)" |
| Database | `23505` | "This record already exists" |
| Database | `PGRST204` | "Database schema error" |
| Database | `PGRST116` | "Requested data not found" |
| Network | `SocketException` | "No internet connection" |
