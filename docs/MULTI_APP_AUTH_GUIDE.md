# Multi-App Authentication Guide

This guide explains how to implement authentication for apps sharing the same Supabase project with user-per-app validation.

---

## Database Schema

### Tables

```sql
-- Main users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Apps registry table
CREATE TABLE apps (
  id TEXT PRIMARY KEY,           -- e.g., 'park_my_whip_resident', 'park_my_whip_admin'
  name TEXT NOT NULL,            -- e.g., 'Park My Whip - Resident'
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Junction table: which users have access to which apps
CREATE TABLE user_apps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  app_id TEXT REFERENCES apps(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'user',      -- 'user', 'admin', etc.
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, app_id)
);
```

### Required RPC Function

This function checks if a user exists AND has access to the specific app in a **single database call**:

```sql
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

GRANT EXECUTE ON FUNCTION public.get_user_by_email_with_app_check(text, text) TO anon, authenticated;
```

---

## App Configuration

Each app must have its own `AppConfig`:

```dart
class AppConfig {
  AppConfig._();
  
  /// Must match the `id` in Supabase `apps` table
  static const String appId = 'your_app_id';
  
  /// Human-readable name
  static const String appName = 'Your App Name';
  
  /// Deep link scheme (for password reset links)
  static const String deepLinkScheme = 'your-app-scheme';
}
```

---

## Authentication Flows

### 1. Login Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     LOGIN FLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User enters email & password                               │
│       │                                                     │
│       ▼                                                     │
│  1. Validate form (email format, password not empty)        │
│       │                                                     │
│       ├─── Invalid ──► Show field errors                    │
│       │                                                     │
│       ▼                                                     │
│  2. Call RPC: get_user_by_email_with_app_check              │
│       │         params: { user_email, p_app_id }            │
│       │                                                     │
│       ├─── Result is null ──► "Account not found"           │
│       │                                                     │
│       ├─── user_app is null ──► "Not registered for app"    │
│       │                                                     │
│       ▼                                                     │
│  3. Call Supabase: auth.signInWithPassword()                │
│       │                                                     │
│       ├─── Success ──► Cache user ──► Dashboard             │
│       │                                                     │
│       └─── Error ──► Show Supabase error                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**RPC Response Scenarios:**

| `user`  | `user_app` | Action                                  |
|---------|------------|-----------------------------------------|
| `null`  | `null`     | Error: "Account not found"              |
| exists  | `null`     | Error: "This account is not registered for this app" |
| exists  | exists     | ✅ Proceed to `signInWithPassword()`    |

**Implementation Example:**

```dart
Future<void> login(String email, String password) async {
  // Step 1: Check user exists AND has app access
  final result = await supabase.client.rpc(
    'get_user_by_email_with_app_check',
    params: {
      'user_email': email,
      'p_app_id': AppConfig.appId,
    },
  );
  
  // Handle null result
  if (result == null) {
    throw Exception('Account not found');
  }
  
  final data = Map<String, dynamic>.from(result);
  
  // Handle user exists but no app access
  if (data['user_app'] == null) {
    throw Exception('This account is not registered for this app');
  }
  
  // Step 2: Proceed with Supabase sign in
  await supabase.auth.signInWithPassword(email: email, password: password);
}
```

---

### 2. Signup Flow (with OTP Verification)

```
┌─────────────────────────────────────────────────────────────┐
│                   SIGNUP FLOW (OTP)                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Page 1: SignupPage                                         │
│       │   - User enters email                               │
│       │   - Validate email format                           │
│       │   - Save email to state                             │
│       ▼                                                     │
│  Page 2: SetPasswordPage                                    │
│       │   - User enters password + confirm password         │
│       │   - Validate password rules (min 8 chars, etc.)     │
│       │   - Validate passwords match                        │
│       ▼                                                     │
│  Call: supabase.auth.signUp(email, password)                │
│       │   └── Supabase auto-sends 6-digit OTP email         │
│       ▼                                                     │
│  Page 3: EnterOtpCodePage                                   │
│       │   - User enters 6-digit OTP from email              │
│       │   - 60-second resend countdown                      │
│       ▼                                                     │
│  Call: supabase.auth.verifyOTP(                             │
│          email: email,                                      │
│          token: otpCode,                                    │
│          type: OtpType.signup                               │
│        )                                                    │
│       │                                                     │
│       ├─── Success ──► User auto-logged in ──► Dashboard    │
│       │                                                     │
│       └─── Error ──► Show error, allow resend               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Points:**
- Supabase **automatically sends OTP** when `signUp()` is called
- User is **auto-logged in** after successful OTP verification
- Resend OTP uses `signInWithOtp()` with 60-second cooldown
- After signup, you need to **create user record** in `users` table and **add to `user_apps`**

**Post-Signup Database Setup:**

```dart
// After successful OTP verification
final userId = supabase.auth.currentUser!.id;

// 1. Create user profile
await supabase.from('users').insert({
  'id': userId,
  'email': email,
  'full_name': email.split('@')[0],
  'created_at': DateTime.now().toIso8601String(),
  'updated_at': DateTime.now().toIso8601String(),
});

// 2. Register user for this app
await supabase.from('user_apps').insert({
  'user_id': userId,
  'app_id': AppConfig.appId,
  'role': 'user',
  'created_at': DateTime.now().toIso8601String(),
  'updated_at': DateTime.now().toIso8601String(),
});
```

---

### 3. Forgot Password / Reset Password Flow

```
┌─────────────────────────────────────────────────────────────┐
│                FORGOT PASSWORD FLOW                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Page 1: ForgotPasswordPage                                 │
│       │   - User enters email                               │
│       │   - Validate email format                           │
│       ▼                                                     │
│  Call: supabase.auth.resetPasswordForEmail(                 │
│          email,                                             │
│          redirectTo: '${AppConfig.deepLinkScheme}://...'    │
│        )                                                    │
│       │                                                     │
│       ▼                                                     │
│  Page 2: ResetLinkSentPage                                  │
│       │   - Show "Check your email" message                 │
│       │   - 60-second resend countdown                      │
│       │   - User clicks link in email                       │
│       ▼                                                     │
│  ┌───────────────────────────────────────────────────┐      │
│  │            DEEP LINK HANDLING                      │      │
│  │                                                    │      │
│  │  Link clicked ──► DeepLinkErrorHandler             │      │
│  │        │                                           │      │
│  │        ├─── Error params? ──► ResetLinkErrorPage   │      │
│  │        │    (expired/invalid token)                │      │
│  │        │                                           │      │
│  │        └─── No errors ──► Supabase processes link  │      │
│  │                    │                               │      │
│  │                    ▼                               │      │
│  │           PASSWORD_RECOVERY auth event             │      │
│  │                    │                               │      │
│  │                    ▼                               │      │
│  │             ResetPasswordPage                      │      │
│  └───────────────────────────────────────────────────┘      │
│       ▼                                                     │
│  Page 3: ResetPasswordPage                                  │
│       │   - User enters new password + confirm              │
│       │   - Validate password rules                         │
│       ▼                                                     │
│  Call: supabase.auth.updateUser(password: newPassword)      │
│       │                                                     │
│       ▼                                                     │
│  Page 4: PasswordResetSuccessPage                           │
│       │   - Show success message                            │
│       │   - Button to return to login                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Deep Link Configuration:**

```dart
// Android: android/app/src/main/AndroidManifest.xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="${AppConfig.deepLinkScheme}" />
</intent-filter>

// iOS: ios/Runner/Info.plist
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>${AppConfig.deepLinkScheme}</string>
        </array>
    </dict>
</array>
```

**Deep Link Error Handling:**

Error deep links contain query params like:
```
your-scheme://reset-password?error=access_denied&error_code=otp_expired
```

Your app should:
1. Intercept ALL deep links before routing
2. Check for `error`, `error_code`, or `error_description` params
3. Navigate to error page if errors found
4. Otherwise let Supabase process the link

**Password Recovery Session Security:**

When `PASSWORD_RECOVERY` event fires, the user has a valid session. To prevent security issues if they abandon the reset:

1. Set a flag: `SharedPreferences.setBool('isRecoveryMode', true)`
2. Clear flag after password update success
3. On app launch, if flag is true → force sign out

---

## Error Handling

Use centralized error handling for Supabase exceptions:

```dart
String getSupabaseErrorMessage(dynamic exception) {
  if (exception is AuthException) {
    // Map auth error codes to user-friendly messages
    switch (exception.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password';
      case 'Email not confirmed':
        return 'Please verify your email first';
      default:
        return exception.message;
    }
  }
  
  if (exception is PostgrestException) {
    return exception.message;
  }
  
  return 'An unexpected error occurred';
}
```

---

## Checklist for New App

- [ ] Create `AppConfig` with unique `appId` matching database
- [ ] Add app to `apps` table in Supabase
- [ ] Configure deep link scheme in Android/iOS
- [ ] Implement login with app access check (RPC call)
- [ ] Implement signup with OTP verification
- [ ] Implement forgot password with deep link handling
- [ ] Add user to `user_apps` table after signup
- [ ] Set up deep link error interceptor
- [ ] Handle password recovery session security

---

## Summary Table

| Flow | Key Supabase Method | Notes |
|------|---------------------|-------|
| Login | `auth.signInWithPassword()` | Check app access FIRST via RPC |
| Signup | `auth.signUp()` | Auto-sends OTP email |
| Verify OTP | `auth.verifyOTP()` | type: `OtpType.signup` |
| Resend OTP | `auth.signInWithOtp()` | 60-second cooldown |
| Forgot Password | `auth.resetPasswordForEmail()` | Include deep link redirect |
| Reset Password | `auth.updateUser()` | After valid recovery session |
