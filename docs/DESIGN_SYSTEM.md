# Design System Documentation

## Overview

The app follows a centralized design system where all visual properties are defined in dedicated files. **Never hardcode colors or text styles.**

---

## Color Palette

**File**: `lib/src/core/constants/colors.dart`

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Primary | `#C8102E` | Buttons, links, active states |
| Primary Dark | `#A50D25` | Pressed states |
| Primary Light | `#E8D0D4` | Backgrounds, highlights |

### Background Colors

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#FFFFFF` | Page backgrounds |
| Surface | `#F8F9FA` | Cards, containers |
| Scaffold | `#FFFFFF` | Scaffold background |

### Text Colors

| Name | Hex | Usage |
|------|-----|-------|
| Text Primary | `#12181C` (Grey 800) | Headings, body text |
| Text Secondary | `#364753` (Grey 700) | Subtitles, captions |
| Text Tertiary | `#5C717E` (Grey 600) | Hints, placeholders |
| Text Disabled | `#8FA2B0` (Grey 400) | Disabled text |

### Status Colors

| Name | Hex | Usage |
|------|-----|-------|
| Success | `#008923` | Success messages, icons |
| Error | `#F73541` | Error messages, validation |
| Warning | `#F5A623` | Warnings |
| Info | `#2196F3` | Information |

### Usage

```dart
// ✅ Good: Use AppColors
Container(
  color: AppColors.primary,
  child: Text('Hello', style: TextStyle(color: AppColors.textPrimary)),
)

// ❌ Bad: Hardcoded colors
Container(
  color: Color(0xFFC8102E),  // Don't do this!
)
```

---

## Typography

**File**: `lib/src/core/constants/text_style.dart`

### Font Family

- **Primary Font**: Urbanist (Google Fonts)

### Text Styles

| Style Name | Weight | Size | Usage |
|------------|--------|------|-------|
| `displayLarge` | Bold | 32sp | Hero text |
| `headlineLarge` | Bold | 24sp | Page titles |
| `headlineMedium` | SemiBold | 20sp | Section headers |
| `titleLarge` | SemiBold | 18sp | Card titles |
| `titleMedium` | Medium | 16sp | Subtitles |
| `bodyLarge` | Regular | 16sp | Body text |
| `bodyMedium` | Regular | 14sp | Secondary body |
| `labelLarge` | SemiBold | 14sp | Button text |
| `labelMedium` | Medium | 12sp | Labels, tags |
| `labelSmall` | Regular | 10sp | Captions |

### Usage

```dart
// ✅ Good: Use Theme text styles
Text(
  'Welcome',
  style: Theme.of(context).textTheme.headlineLarge,
)

// With color override
Text(
  'Subtitle',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: AppColors.textSecondary,
  ),
)

// ❌ Bad: Hardcoded styles
Text(
  'Welcome',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),  // Don't!
)
```

---

## Spacing

**File**: `lib/src/core/helpers/spacing.dart`

Uses `flutter_screenutil` for responsive sizing.

### Spacing Helpers

```dart
// Vertical spacing
verticalSpace(8)   // 8.h
verticalSpace(16)  // 16.h
verticalSpace(24)  // 24.h

// Horizontal spacing
horizontalSpace(8)   // 8.w
horizontalSpace(16)  // 16.w
```

### Responsive Units

```dart
// Width-based
16.w   // 16 logical pixels scaled by width

// Height-based
16.h   // 16 logical pixels scaled by height

// Smaller of width/height (for square elements)
16.r   // 16 logical pixels scaled by min(width, height)

// Font size
16.sp  // 16 logical pixels for fonts
```

### Common Spacing Values

| Value | Usage |
|-------|-------|
| 4 | Tight spacing (between icon and text) |
| 8 | Small spacing (between related items) |
| 16 | Medium spacing (between sections) |
| 24 | Large spacing (page margins) |
| 32 | Extra large (major section breaks) |

---

## Reusable Widgets

### CommonButton

**File**: `lib/src/core/widgets/common_button.dart`

Primary action button with loading state.

```dart
CommonButton(
  text: 'Login',
  onPressed: () => cubit.signIn(),
  isLoading: state.isLoading,
  isEnabled: state.isButtonEnabled,
)

// Full width (default)
CommonButton(text: 'Submit', onPressed: () {})

// Custom width
CommonButton(
  text: 'Save',
  onPressed: () {},
  width: 200.w,
)
```

### CustomTextField

**File**: `lib/src/core/widgets/custom_text_field.dart`

Text input with validation support.

```dart
CustomTextField(
  controller: cubit.emailController,
  hintText: 'Email address',
  keyboardType: TextInputType.emailAddress,
  errorText: state.emailError,
  onChanged: (_) => cubit.validateEmail(),
  prefixIcon: Icons.email_outlined,
)

// Password field
CustomTextField(
  controller: cubit.passwordController,
  hintText: 'Password',
  obscureText: true,
  errorText: state.passwordError,
  onChanged: (_) => cubit.validatePassword(),
  prefixIcon: Icons.lock_outline,
)
```

### CommonAppBar

**File**: `lib/src/core/widgets/common_app_bar.dart`

Standardized app bar.

```dart
Scaffold(
  appBar: CommonAppBar(
    title: 'Profile',
    showBackButton: true,
    actions: [
      IconButton(
        icon: Icon(Icons.settings),
        onPressed: () {},
      ),
    ],
  ),
)
```

### ErrorDialog

**File**: `lib/src/core/widgets/error_dialog.dart`

Modal dialog for displaying errors.

```dart
showDialog(
  context: context,
  builder: (_) => ErrorDialog(
    title: 'Error',
    errorMessage: 'Something went wrong. Please try again.',
    onDismiss: () => Navigator.pop(context),
  ),
);

// Or use NetworkExceptions helper
NetworkExceptions.showErrorDialog(error, title: 'Failed to Save');
```

---

## Theme Configuration

**File**: `lib/src/core/app_style/app_theme.dart`

```dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      headlineLarge: AppTextStyles.headlineLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      // ... all text styles
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.error),
      ),
    ),
  );
}
```

---

## Icon System

**File**: `lib/src/core/constants/app_icons.dart`

```dart
class AppIcons {
  static const IconData email = Icons.email_outlined;
  static const IconData password = Icons.lock_outline;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData car = Icons.directions_car_outlined;
  // ... more icons
}
```

---

## Design Checklist

- [ ] Colors from `AppColors` only
- [ ] Text styles from `Theme.of(context).textTheme`
- [ ] Spacing using `.h`, `.w`, `.r`, `.sp` extensions
- [ ] Use `verticalSpace()` / `horizontalSpace()` helpers
- [ ] Buttons via `CommonButton` widget
- [ ] Text fields via `CustomTextField` widget
- [ ] App bars via `CommonAppBar` widget
- [ ] Errors via `ErrorDialog` or `NetworkExceptions.showErrorDialog()`
