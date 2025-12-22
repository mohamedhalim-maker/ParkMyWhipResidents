# Coding Conventions

## Import Rules

### Always Use Absolute Imports

```dart
// ✅ Good
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/login/login_cubit.dart';

// ❌ Bad
import '../constants/colors.dart';
import '../../cubit/login/login_cubit.dart';
```

### Import Order

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:developer';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. External packages
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 4. Project imports
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
```

---

## Naming Conventions

### Files

| Type | Convention | Example |
|------|------------|---------|
| Pages | `snake_case_page.dart` | `login_page.dart` |
| Widgets | `snake_case.dart` | `vehicle_card.dart` |
| Cubits | `feature_cubit.dart` | `login_cubit.dart` |
| States | `feature_state.dart` | `login_state.dart` |
| Models | `model_name.dart` | `user_model.dart` |
| Services | `feature_service.dart` | `vehicle_service.dart` |
| Constants | `descriptive_name.dart` | `colors.dart` |

### Classes

| Type | Convention | Example |
|------|------------|---------|
| Pages | `FeatureNamePage` | `LoginPage`, `VehicleListPage` |
| Widgets | `DescriptiveName` | `VehicleCard`, `PasswordValidationRules` |
| Cubits | `FeatureCubit` | `LoginCubit`, `VehicleCubit` |
| States | `FeatureState` | `LoginState`, `VehicleState` |
| Models | `ModelName` | `User`, `Vehicle` |
| Services | `FeatureService` | `VehicleService` |

### Variables & Methods

```dart
// Variables: camelCase
final String userName = 'John';
final bool isLoading = false;
final List<Vehicle> vehicles = [];

// Private: prefix with underscore
final String _tableName = 'vehicles';
User? _currentUser;

// Methods: camelCase, verb-first
void validateEmail() { ... }
Future<User?> signInWithEmail() { ... }
void _handleAuthError() { ... }
```

### Constants

```dart
// Class with static const (preferred)
class RoutesName {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
}

// Or top-level const for simple values
const double kDefaultPadding = 16.0;
```

---

## Widget Guidelines

### Pages are StatelessWidget

```dart
// ✅ Good: StatelessWidget with BlocBuilder
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) { ... },
      builder: (context, state) { ... },
    );
  }
}

// ❌ Bad: StatefulWidget for pages
class LoginPage extends StatefulWidget { ... }
```

### Extract Widgets as Classes (Not Functions)

```dart
// ✅ Good: Public class
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  
  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(...);
  }
}

// ❌ Bad: Private function returning Widget
Widget _buildVehicleCard(Vehicle vehicle) {
  return Card(...);
}
```

### Use const Constructors

```dart
// ✅ Good
const VehicleCard({super.key, required this.vehicle});

return const SizedBox(height: 16);
return const CircularProgressIndicator();

// ❌ Bad (when const is possible)
VehicleCard({super.key, required this.vehicle});
return SizedBox(height: 16);
```

---

## State Management Rules

### Controllers Belong to Cubit

```dart
// ✅ Good: Controllers in Cubit
class LoginCubit extends Cubit<LoginState> {
  final emailController = TextEditingController();
  
  @override
  Future<void> close() {
    emailController.dispose();
    return super.close();
  }
}

// ❌ Bad: Controllers in Page
class LoginPage extends StatefulWidget {
  final emailController = TextEditingController(); // Don't!
}
```

### Clear Errors Before Operations

```dart
Future<void> signIn() async {
  // Clear previous error
  emit(state.copyWith(isLoading: true, generalError: null));
  
  try {
    // ...
  } catch (e) {
    emit(state.copyWith(isLoading: false, generalError: message));
  }
}
```

### Use copyWith for State Updates

```dart
// ✅ Good: Immutable update
emit(state.copyWith(isLoading: true));

// ❌ Bad: Mutating state
state.isLoading = true; // NEVER do this
emit(state);
```

---

## Error Handling

### Use NetworkExceptions

```dart
// ✅ Good: Centralized error handling
try {
  await someOperation();
} catch (e) {
  final message = NetworkExceptions.getSupabaseExceptionMessage(e);
  emit(state.copyWith(generalError: message));
}

// ❌ Bad: Manual error message
try {
  await someOperation();
} catch (e) {
  emit(state.copyWith(generalError: e.toString())); // Don't!
}
```

### Log Errors with dart:developer

```dart
import 'dart:developer';

try {
  await someOperation();
} catch (e, stackTrace) {
  log('Error in signIn', name: 'LoginCubit', error: e, stackTrace: stackTrace);
  // ...
}
```

---

## Styling Rules

### Never Hardcode Colors

```dart
// ✅ Good
Container(color: AppColors.primary)
Text('Hello', style: TextStyle(color: AppColors.textPrimary))

// ❌ Bad
Container(color: Color(0xFFC8102E))
Text('Hello', style: TextStyle(color: Colors.black87))
```

### Never Hardcode Text Styles

```dart
// ✅ Good
Text('Title', style: Theme.of(context).textTheme.headlineLarge)

// ❌ Bad
Text('Title', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
```

### Use Responsive Units

```dart
// ✅ Good
SizedBox(height: 16.h)
Padding(padding: EdgeInsets.all(24.w))
Text('Hello', style: TextStyle(fontSize: 16.sp))
BorderRadius.circular(12.r)

// ❌ Bad
SizedBox(height: 16)
Padding(padding: EdgeInsets.all(24))
```

---

## Documentation

### Document Public APIs

```dart
/// Service for managing vehicle data operations.
/// 
/// Provides CRUD operations for vehicles stored in Supabase.
class VehicleService {
  /// Fetches all vehicles for a specific user.
  /// 
  /// Returns an empty list if no vehicles are found.
  /// Throws [PostgrestException] on database errors.
  Future<List<Vehicle>> getVehicles(String userId) async { ... }
}
```

### Use TODO Comments

```dart
// TODO: Implement email verification when needed
Future<void> sendEmailVerification() async { }

// TODO(john): Refactor this after v2 release
```

---

## Code Quality Checklist

- [ ] Absolute imports only
- [ ] StatelessWidget for pages
- [ ] Widgets extracted as classes, not functions
- [ ] Controllers in Cubit, disposed in close()
- [ ] Colors from AppColors
- [ ] Text styles from Theme
- [ ] Responsive units (.h, .w, .sp, .r)
- [ ] Errors through NetworkExceptions
- [ ] dart:developer for logging
- [ ] const constructors where possible
- [ ] Public API documentation
