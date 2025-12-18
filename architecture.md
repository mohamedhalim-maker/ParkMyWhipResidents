# Park My Whip Resident App - Architecture

## Overview
This is a Flutter application for residents to manage parking spots, vehicles, guest passes, and violations. The app follows Clean Architecture principles with BLoC pattern for state management.

## Architecture Pattern
- **Clean Architecture**: Separation of concerns with clear layers
- **BLoC Pattern**: Using Cubit for state management
- **Dependency Injection**: Using GetIt for DI container

## Project Structure

```
lib/
├── main.dart                                   # App entry point
├── park_my_whip_resident_app.dart             # Main app widget
├── supabase/
│   └── supabase_config.dart                   # Supabase initialization
└── src/
    ├── core/                                  # Shared core modules
    │   ├── app_style/
    │   │   └── app_theme.dart                 # App theme configuration
    │   ├── constants/
    │   │   ├── colors.dart                    # Color palette
    │   │   ├── text_style.dart                # Text styles
    │   │   └── strings.dart                   # App strings
    │   ├── helpers/
    │   │   ├── spacing.dart                   # Spacing helpers
    │   │   └── shared_pref_helper.dart        # Local storage
    │   ├── widgets/                           # Reusable widgets
    │   │   ├── common_button.dart
    │   │   ├── common_app_bar.dart
    │   │   ├── custom_text_field.dart
    │   │   └── error_dialog.dart
    │   ├── routes/
    │   │   ├── router.dart                    # Route configuration
    │   │   └── names.dart                     # Route names
    │   ├── networking/
    │   │   └── network_exceptions.dart        # Error handling
    │   ├── config/
    │   │   └── injection.dart                 # Dependency injection
    │   ├── models/
    │   │   └── supabase_user_model.dart       # User model
    │   └── services/
    │       └── supabase_user_service.dart     # User service
    │
    └── features/                              # Feature modules
        ├── auth/                              # Authentication feature
        │   ├── data/
        │   │   └── data_sources/
        │   │       └── auth_remote_data_source.dart
        │   ├── domain/
        │   │   └── validators.dart
        │   └── presentation/
        │       ├── cubit/
        │       │   ├── auth_cubit.dart
        │       │   └── auth_state.dart
        │       └── pages/
        │           └── login_page.dart
        │
        └── dashboard/                         # Dashboard feature
            └── presentation/
                └── pages/
                    └── dashboard_page.dart
```

## Current Implementation Status

### ✅ Completed
1. **Core Architecture**
   - Color system with centralized palette
   - Text styles using Google Fonts (Urbanist)
   - Responsive design with flutter_screenutil
   - Spacing helpers
   - App theme configuration

2. **Common Widgets**
   - CommonButton: Reusable button component
   - CustomTextField: Text input with validation
   - CommonAppBar: Standardized app bar
   - ErrorDialog: Error display dialog

3. **State Management**
   - BLoC pattern with Cubit
   - Equatable for state comparison
   - GetIt for dependency injection

4. **Authentication Feature**
   - Login/Signup page with form validation
   - Supabase authentication integration
   - User service with local caching
   - Email/password validation
   - Error handling

5. **Dashboard**
   - Basic dashboard layout
   - Feature cards for navigation
   - Placeholder for future features

6. **Routing**
   - Named route system
   - Initial route detection based on auth state
   - BlocProvider integration in routes

### 🚧 Next Steps (To Be Implemented)

1. **Parking Feature**
   - View assigned parking spot
   - Request parking spot
   - Parking spot details

2. **Vehicle Management**
   - Add/edit/delete vehicles
   - Vehicle listing
   - Vehicle details

3. **Guest Pass Management**
   - Create guest passes
   - List active/expired passes
   - Guest pass details

4. **Violations**
   - View violations
   - Violation details
   - Payment integration

## Key Technologies
- **Flutter**: Cross-platform framework
- **Supabase**: Backend (Auth, Database, Storage)
- **flutter_bloc**: State management
- **get_it**: Dependency injection
- **flutter_screenutil**: Responsive design
- **google_fonts**: Typography
- **shared_preferences**: Local storage
- **equatable**: Value comparison

## Design System

### Colors
- Primary: Rich Red (#C8102E)
- Background: White (#FFFFFF)
- Text Primary: Grey 800 (#12181C)
- Text Secondary: Grey 700 (#364753)
- Success: Green (#008923)
- Error: Red (#F73541)

### Typography
- Primary Font: Urbanist
- Responsive sizing with .sp extension
- Predefined text styles for consistency

### Spacing
- Uses flutter_screenutil for responsive spacing
- Helper functions: verticalSpace() and horizontalSpace()

## State Management Pattern

### Cubit Structure
```dart
class FeatureCubit extends Cubit<FeatureState> {
  // Dependencies injected via constructor
  // Text controllers for forms
  // Business logic methods
  // Dispose controllers in close()
}
```

### State Structure
```dart
class FeatureState extends Equatable {
  // State properties
  // copyWith method
  // props for Equatable
}
```

### Page Structure
```dart
class FeaturePage extends StatelessWidget {
  // BlocBuilder/BlocConsumer for state
  // UI rendering based on state
  // Access cubit via getIt<FeatureCubit>()
}
```

## Error Handling
- NetworkExceptions class for centralized error handling
- User-friendly error messages
- Logging with dart:developer
- Error dialogs for critical errors

## Supabase Setup
⚠️ **Important**: Before using the app, update the Supabase configuration in:
`lib/supabase/supabase_config.dart`

Replace placeholders with your actual Supabase credentials:
- YOUR_SUPABASE_URL
- YOUR_SUPABASE_ANON_KEY

## Development Guidelines

### Code Conventions
1. Use absolute imports (never relative)
2. All pages are StatelessWidget
3. Extract reusable widgets as public classes
4. Never hardcode colors or text styles
5. Use responsive units (.sp, .h, .w, .r)
6. Define all strings in strings.dart
7. Use try-catch with logging
8. Dispose controllers in cubit.close()

### Adding New Features
1. Create feature folder in src/features/
2. Follow clean architecture structure (data/domain/presentation)
3. Create models with fromJson/toJson/copyWith
4. Create data sources (abstract + Supabase implementation)
5. Create cubit with state (extends Equatable)
6. Create pages as StatelessWidget with BlocBuilder
7. Register dependencies in injection.dart
8. Add routes in routes/names.dart and routes/router.dart

## Testing Strategy
- Unit tests for business logic (cubits)
- Widget tests for UI components
- Integration tests for complete flows
- Mock Supabase for testing

## Next Phase Development
1. Complete Supabase setup with actual credentials
2. Implement parking spot feature
3. Implement vehicle management
4. Implement guest pass system
5. Implement violations feature
6. Add profile management
7. Add notifications
8. Add analytics

## Notes
- The app uses Material Design 3
- All UI is responsive and works on all screen sizes
- The architecture allows for easy code sharing between admin and resident apps
- Follow the patterns established in the auth feature for new features
