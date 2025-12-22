# Authentication Architecture - Testable Design

## Overview
The authentication system has been refactored to follow SOLID principles with a clean, testable architecture. The design separates concerns into distinct layers with clear responsibilities.

## Architecture Layers

### 1. **Data Layer** (No UI Dependencies)
   - `AuthManager` - Abstract interface defining auth contract
   - `SupabaseAuthManager` - Concrete implementation for Supabase
   - `UserProfileRepository` - Handles user profile CRUD operations
   - `UserAppRepository` - Manages app registration operations
   - `UserCacheService` - Local caching with SharedPreferences

### 2. **Domain Layer**
   - `User` - User model
   - `UserApp` - User app registration model

### 3. **Presentation Layer**
   - ViewModels/BLoCs consume AuthManager
   - UI widgets (no direct data layer access)

## SOLID Principles Applied

### Single Responsibility Principle (SRP)
Each class has one clear responsibility:
- `SupabaseAuthManager` - Authentication operations only
- `UserProfileRepository` - User profile database operations
- `UserAppRepository` - App registration operations
- `UserCacheService` - Local caching operations
- `AuthConstants` - Centralized constants

### Open/Closed Principle (OCP)
- `AuthManager` is abstract, open for extension via mixins
- New auth providers (Firebase, Auth0) can be added without modifying existing code
- Mixins allow selective feature composition

### Liskov Substitution Principle (LSP)
- Any `AuthManager` implementation can replace another
- Repositories are interchangeable through constructor injection

### Interface Segregation Principle (ISP)
- Split authentication methods into focused mixins:
  - `EmailSignInManager` - Email/password auth
  - `GoogleSignInManager` - Google OAuth
  - `AppleSignInManager` - Apple Sign-In
  - etc.
- Clients only depend on methods they use

### Dependency Inversion Principle (DIP)
- `SupabaseAuthManager` depends on abstractions (repositories)
- Dependencies injected via constructor
- Easy to swap implementations for testing

## Dependency Injection

```dart
// Production
final authManager = SupabaseAuthManager(
  sharedPrefHelper: SharedPrefHelper(),
  userProfileRepository: UserProfileRepository(),
  userAppRepository: UserAppRepository(),
);

// Testing with mocks
final authManager = SupabaseAuthManager(
  sharedPrefHelper: MockSharedPrefHelper(),
  userProfileRepository: MockUserProfileRepository(),
  userAppRepository: MockUserAppRepository(),
);
```

## Testing Strategy

### Unit Tests

#### 1. **Repository Tests**
```dart
// Example: UserProfileRepository test
test('createUserProfile should insert user data', () async {
  final repository = UserProfileRepository();
  
  await repository.createUserProfile(
    userId: 'test-id',
    email: 'test@example.com',
  );
  
  final user = await repository.getUserProfile('test-id');
  expect(user?.email, 'test@example.com');
});
```

#### 2. **Cache Service Tests**
```dart
// Example: UserCacheService test
test('cacheUser should save user to SharedPreferences', () async {
  final mockHelper = MockSharedPrefHelper();
  final cacheService = UserCacheService(mockHelper);
  
  final user = User(id: '123', email: 'test@example.com', ...);
  await cacheService.cacheUser(user);
  
  verify(mockHelper.saveObject('user_profile', any)).called(1);
  verify(mockHelper.saveString('user_id', '123')).called(1);
});
```

#### 3. **AuthManager Tests**
```dart
// Example: SupabaseAuthManager test
test('signInWithEmail should validate app registration', () async {
  final mockUserAppRepo = MockUserAppRepository();
  final mockProfileRepo = MockUserProfileRepository();
  final mockCache = MockUserCacheService();
  
  when(mockUserAppRepo.getUserAppRegistration(any, any))
      .thenAnswer((_) async => null);
  
  final authManager = SupabaseAuthManager(
    sharedPrefHelper: MockSharedPrefHelper(),
    userProfileRepository: mockProfileRepo,
    userAppRepository: mockUserAppRepo,
  );
  
  expect(
    () => authManager.signInWithEmail('test@example.com', 'password'),
    throwsException,
  );
});
```

### Integration Tests

#### 1. **Auth Flow Tests**
```dart
testWidgets('complete signup flow', (tester) async {
  // Test full signup -> verify email -> login flow
});
```

#### 2. **Database Integration**
```dart
test('user creation and retrieval', () async {
  // Test actual database operations with test Supabase instance
});
```

### Widget Tests

```dart
testWidgets('LoginScreen shows error on invalid credentials', (tester) async {
  final mockAuthManager = MockAuthManager();
  
  when(mockAuthManager.signInWithEmail(any, any))
      .thenThrow(Exception('Invalid credentials'));
  
  await tester.pumpWidget(LoginScreen(authManager: mockAuthManager));
  
  // Interact with UI and verify error display
});
```

## Mocking Guide

### Using Mockito

1. **Create mock classes:**
```dart
@GenerateMocks([
  UserProfileRepository,
  UserAppRepository,
  SharedPrefHelper,
])
void main() {}
```

2. **Run code generation:**
```bash
flutter pub run build_runner build
```

3. **Use in tests:**
```dart
final mockRepo = MockUserProfileRepository();
when(mockRepo.getUserProfile(any)).thenAnswer((_) async => testUser);
```

## Benefits of This Architecture

### 1. **Testability**
- Pure functions without UI dependencies
- Easy to mock dependencies
- Fast unit tests without Flutter Test framework

### 2. **Maintainability**
- Clear separation of concerns
- Single responsibility per class
- Easy to locate and fix bugs

### 3. **Scalability**
- Add new auth providers without touching existing code
- Extend functionality through mixins
- Repository pattern allows database migration

### 4. **Reusability**
- Repositories can be used across features
- AuthManager can be shared between apps
- Cache service is generic

## Migration from Old Code

### Breaking Changes
1. **BuildContext removed from data layer:**
   ```dart
   // Old
   await authManager.signInWithEmail(context, email, password);
   
   // New
   await authManager.signInWithEmail(email, password);
   ```

2. **Constructor injection:**
   ```dart
   // Old
   final authManager = SupabaseAuthManager(sharedPrefHelper);
   
   // New
   final authManager = SupabaseAuthManager(
     sharedPrefHelper: sharedPrefHelper,
     userProfileRepository: UserProfileRepository(),
     userAppRepository: UserAppRepository(),
   );
   ```

### Update Checklist
- [ ] Remove BuildContext from all auth method calls in UI layer
- [ ] Update SupabaseAuthManager instantiation with new constructor
- [ ] Update any direct SupabaseService calls to use repositories
- [ ] Replace hard-coded strings with AuthConstants
- [ ] Update error handling (NetworkExceptions still works)

## Best Practices

1. **Always inject dependencies** - Don't create them inside classes
2. **Use constants** - Never hard-code table names or cache keys
3. **Log consistently** - Use `log()` with `AuthConstants.loggerName`
4. **Handle errors gracefully** - Non-critical failures shouldn't break auth flow
5. **Cache smart** - Cache on success, clear on failure
6. **Validate early** - Check app registration before profile operations

## Future Enhancements

1. **Add refresh token handling**
2. **Implement biometric authentication**
3. **Add session management service**
4. **Create auth state stream**
5. **Add analytics integration**
6. **Implement rate limiting**

## File Structure

```
lib/
└── src/
    └── features/
        └── auth/
            └── data/
                ├── auth_constants.dart          # Constants
                ├── auth_manager.dart             # Abstract interfaces
                ├── supabase_auth_manager.dart    # Supabase implementation
                ├── user_profile_repository.dart  # User CRUD
                ├── user_app_repository.dart      # App registration CRUD
                └── user_cache_service.dart       # Local caching
```

## Dependencies

```yaml
dependencies:
  supabase_flutter: ^latest
  shared_preferences: ^latest

dev_dependencies:
  mockito: ^latest
  build_runner: ^latest
```
