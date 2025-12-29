# Onboarding Feature

## 📋 Overview

The onboarding feature collects essential user information after successful authentication. This is a **multi-step flow** that guides users through providing personal details and determining their user type (Resident or Visitor). The resident flow includes additional steps for address setup and community selection.

## 🏗️ Architecture

This feature follows the **Clean Architecture** pattern with:
- **Data Layer**: Models and services for data persistence
- **Domain Layer**: Validation logic
- **Presentation Layer**: Cubit, pages, and widgets

### Directory Structure

```
lib/src/features/onboarding/
├── data/
│   ├── models/
│   │   ├── onboarding_data_model.dart        # Aggregated onboarding data
│   │   └── permit_plan_model.dart            # Permit plan model (period, price, value)
│   └── services/
│       └── onboarding_service.dart           # Save to Supabase
│
├── domain/
│   └── validators.dart                       # Field validation logic
│
└── presentation/
    ├── cubit/
    │   ├── general/                          # General onboarding flow (Steps 1-2)
    │   │   ├── general_onboarding_cubit.dart # Business logic for user info & type
    │   │   └── general_onboarding_state.dart # State for general flow
    │   └── resident/                         # Resident-specific flow
    │       ├── resident_onboarding_cubit.dart # Business logic for resident flow
    │       └── resident_onboarding_state.dart # State for resident flow
    │
    ├── pages/                                # Onboarding pages
    │   ├── user_name_page.dart               # Step 1: First/Last name
    │   ├── user_type_page.dart               # Step 2: Resident/Visitor selection
    │   └── resident/                         # Resident-specific flow
    │       ├── setup_address_page.dart       # Resident Step 1: Community selection
    │       ├── add_building_unit_page.dart   # Resident Step 2: Building & Unit numbers
    │       └── select_permit_plan_page.dart  # Resident Step 3: Permit plan selection
    │
    └── widgets/                              # Reusable components
        ├── selection_card.dart               # Selection option card
        ├── terms_checkbox.dart               # Terms acceptance checkbox
        ├── general/                          # General reusable widgets
        │   ├── contact_us_text.dart          # "Have questions? Contact us" link
        │   ├── selection_indicator.dart      # Radio button indicator
        │   └── step_progress_indicator.dart  # Progress bar for steps
        └── resident/                         # Resident-specific widgets
            ├── choose_community_field.dart   # Community selection field
            ├── permit_plan_card.dart         # Permit plan option card (period + price)
            ├── community_selection_item.dart # Community list item
            └── community_selection_bottom_sheet.dart # Community search modal
```

---

## 🔄 State Management

### Architecture: Separated Cubits

The onboarding flow is managed by **two separate singleton cubits** to maintain clean separation of concerns:

1. **GeneralOnboardingCubit** - Manages Steps 1-2 (user name and user type)
2. **ResidentOnboardingCubit** - Manages resident-specific flow (community selection, address setup)

This separation provides:
- ✅ **Clear boundaries** between general and flow-specific logic
- ✅ **No data redundancy** - data is passed via navigation arguments
- ✅ **Easier maintenance** - each cubit focuses on its own flow
- ✅ **Scalability** - easy to add visitor flow without touching resident code

### GeneralOnboardingCubit (Singleton)

Manages the **general onboarding flow** (Steps 1-2):

```dart
class GeneralOnboardingCubit extends Cubit<GeneralOnboardingState> {
  // ==================== Controllers ====================
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  bool termsAccepted = false;
  
  // ==================== Field Change Handlers ====================
  void onFirstNameChanged();
  void onLastNameChanged();
  void onTermsChanged(bool value);
  
  // ==================== Validation ====================
  void onContinuePersonalInfo({required BuildContext context});
  
  // ==================== User Type Selection ====================
  void onUserTypeChanged(String userType);
  void onContinueUserType({required BuildContext context});
  
  // ==================== Lifecycle ====================
  void resetOnboarding();
}
```

**Responsibilities:**
- User name input (first name, last name)
- Terms acceptance checkbox
- User type selection (Resident/Visitor)
- Navigation to Step 2 and to flow-specific pages
- Passes user data to next flow via navigation arguments

### GeneralOnboardingState

```dart
class GeneralOnboardingState extends Equatable {
  final bool isButtonEnabled;              // Auto-enabled when form is valid
  final String? firstNameError;            // Validation error for first name
  final String? lastNameError;             // Validation error for last name
  final String? selectedUserType;          // 'resident' or 'visitor'
}
```

### ResidentOnboardingCubit (Singleton)

Manages the **resident-specific onboarding flow**:

```dart
class ResidentOnboardingCubit extends Cubit<ResidentOnboardingState> {
  // User data from general onboarding
  String? firstName;
  String? lastName;
  
  // ==================== Initialization ====================
  void initializeWithUserData({required String firstName, required String lastName});
  
  // ==================== Community Selection ====================
  void onChooseCommunityTapped({required BuildContext context});
  void onCommunitySearchChanged(String query);
  void onTempCommunitySelected(String community);
  void onCommunitySaved();
  
  // ==================== Building & Unit Number ====================
  void onUnitNumberChanged();
  void onBuildingNumberChanged();
  void onContinueAddBuildingUnit({required BuildContext context});
  
  // ==================== Permit Plan Selection ====================
  void onPermitPlanSelected(PermitPlanModel plan);
  void onContinueSelectPermitPlan({required BuildContext context});
  
  // ==================== Back Navigation ====================
  void clearBuildingUnitData();
  void clearPermitPlanData();
  
  // ==================== Navigation ====================
  void onContinueSetupAddress({required BuildContext context});
  
  // ==================== Final Submission ====================
  Future<void> submitResidentOnboarding({required BuildContext context});
  
  // ==================== Lifecycle ====================
  void resetOnboarding();
}
```

**Responsibilities:**
- Receives user data from general onboarding via `initializeWithUserData()`
- Community selection with search and filtering
- Address setup and validation
- Building and unit number validation
- Back navigation cleanup (clears controllers and resets state)
- Resident-specific data accumulation
- Final submission to backend

### ResidentOnboardingState

```dart
class ResidentOnboardingState extends Equatable {
  final bool isButtonEnabled;              // Auto-enabled when form is valid
  final String? selectedCommunity;         // Selected community name
  final String communitySearchQuery;       // Current search query
  final List<String> filteredCommunities;  // Filtered community list
  final String? tempSelectedCommunity;     // Temp selection in bottom sheet
  final String? unitNumberError;           // Validation error for unit number (red border only)
  final String? buildingNumberError;       // Validation error for building number (red border only)
  final PermitPlanModel? selectedPermitPlan; // Selected permit plan (weekly/monthly/yearly)
}
```

**Key Points:**
- ✅ **Singleton Cubits**: Each cubit is a singleton shared across its pages
- ✅ **Data Passing**: User data flows from general to resident via navigation arguments
- ✅ **Immutable State**: All states are immutable with copyWith methods
- ✅ **Button State Reset**: Each cubit resets button state on navigation
- ✅ **Individual Error Fields**: Clear validation error display

---

## 📐 User Flow

```
Auth Success (Login/Signup)
    ↓
Check user.onboarding_completed
    ↓
    ├─── false → START ONBOARDING
    │               ↓
    │            Step 1: UserNamePage (Personal Info)
    │               ├─ First Name
    │               ├─ Last Name
    │               └─ Terms Acceptance
    │               ↓
    │            Step 2: UserTypePage
    │               ├─ Resident (leads to Resident Flow)
    │               └─ Visitor (leads to Visitor Flow)
    │               ↓
    │            ┌──────────────────┐
    │            │  RESIDENT FLOW   │
    │            └──────────────────┘
    │               ↓
    │            Resident Step 1: SetupAddressPage
    │               └─ Choose Community
    │               ↓
    │            [More resident steps to be added]
    │               ↓
    │            Submit to Supabase
    │               ↓
    │            Navigate to Dashboard
    │               ↓
    │            Set onboarding_completed = true
    │
    └─── true → Navigate to Dashboard directly
```

---

## 🎨 Page Structure Pattern

Each page follows the same pattern. Here's a real example from `UserNamePage`:

```dart
class UserNamePage extends StatelessWidget {
  const UserNamePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        onBackPress: () {}, // Will be implemented in cubit
      ),
      body: BlocBuilder<GeneralOnboardingCubit, GeneralOnboardingState>(
        builder: (context, state) {
          final cubit = context.read<GeneralOnboardingCubit>();
          
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                verticalSpace(12),
                
                // Page title (28px)
                Text(
                  OnboardingStrings.whatsYourName,
                  style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                ),
                
                verticalSpace(24),
                
                // First name field
                CustomTextField(
                  title: OnboardingStrings.firstName,
                  hintText: OnboardingStrings.firstNameHint,
                  controller: cubit.firstNameController,
                  validator: (_) => state.firstNameError,
                  onChanged: (_) => cubit.onFirstNameChanged(),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                ),
                
                verticalSpace(16),
                
                // Last name field
                CustomTextField(
                  title: OnboardingStrings.lastName,
                  hintText: OnboardingStrings.lastNameHint,
                  controller: cubit.lastNameController,
                  validator: (_) => state.lastNameError,
                  onChanged: (_) => cubit.onLastNameChanged(),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.done,
                ),
                
                verticalSpace(20),
                
                // Terms & Conditions Checkbox
                TermsCheckbox(
                  text: OnboardingStrings.termsCheckboxText,
                  value: cubit.termsAccepted,
                  onChanged: (value) => cubit.onTermsChanged(value ?? false),
                ),
                
                Spacer(),
                
                // Already have account text
                AccountTextToggle(
                  normalText: OnboardingStrings.alreadyHaveAccount,
                  actionText: OnboardingStrings.logIn,
                  onTap: () {}, // Will navigate to login
                ),
                
                verticalSpace(16),
                
                // Continue Button
                CommonButton(
                  text: OnboardingStrings.continueButton,
                  onPressed: () => cubit.onContinuePersonalInfo(context: context),
                  isEnabled: state.isButtonEnabled,
                ),
                
                verticalSpace(24),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### 🔗 How UI Links to State Management

#### 1. **BlocBuilder Wraps the UI**
```dart
// General onboarding pages (Steps 1-2)
BlocBuilder<GeneralOnboardingCubit, GeneralOnboardingState>(
  builder: (context, state) {
    final cubit = context.read<GeneralOnboardingCubit>();
    // ... build UI using state and cubit
  },
)

// Resident flow pages
BlocBuilder<ResidentOnboardingCubit, ResidentOnboardingState>(
  builder: (context, state) {
    final cubit = context.read<ResidentOnboardingCubit>();
    // ... build UI using state and cubit
  },
)
```
- `state` provides reactive data (errors, button state)
- `cubit` provides methods (field handlers, validation)
- Each page uses the appropriate cubit for its flow

#### 2. **TextFields Connected to Controllers**
```dart
CustomTextField(
  controller: cubit.firstNameController,  // Cubit owns controller
  validator: (_) => state.firstNameError, // State provides error
  onChanged: (_) => cubit.onFirstNameChanged(), // Notify cubit of changes
)
```
- **Controller**: Managed by cubit (survives page navigation)
- **Validator**: Reads error from state (reactive)
- **onChanged**: Clears error and updates button state

#### 3. **Button State Driven by Cubit**
```dart
CommonButton(
  text: OnboardingStrings.continueButton,
  onPressed: () => cubit.onContinuePersonalInfo(context: context),
  isEnabled: state.isButtonEnabled, // Auto-enabled when form valid
  width: 110.w, // Optional width parameter (defaults to infinity)
)
```
- Button enabled/disabled based on real-time validation
- Pressing button triggers validation in cubit
- Errors are emitted to state → UI auto-updates
- **NEW**: `width` parameter allows custom button widths

#### 4. **Checkbox State Synced**
```dart
TermsCheckbox(
  value: cubit.termsAccepted,  // Read from cubit
  onChanged: (value) => cubit.onTermsChanged(value ?? false), // Update cubit
)
```
- Checkbox value stored in cubit (not state, as it's not reactive)
- Changing checkbox updates button state through cubit

### 📋 State Management Flow

```
User Action (e.g., types in field)
    ↓
onChanged callback
    ↓
Cubit method (e.g., onFirstNameChanged())
    ↓
Clear error in state: emit(state.copyWith(firstNameError: null))
    ↓
Update button state: _updateButtonState()
    ↓
Check if all fields valid: _isPersonalInfoValid()
    ↓
Emit new state: emit(state.copyWith(isButtonEnabled: true))
    ↓
BlocBuilder rebuilds UI
    ↓
Button becomes enabled
```

### 🔄 Validation Flow

```
User presses Continue button
    ↓
cubit.onContinuePersonalInfo(context: context)
    ↓
Validate both fields using domain validators
    ↓
    ├─ Both valid?
    │   ↓
    │   Clear any errors: emit(state.copyWith(firstNameError: null, lastNameError: null))
    │   ↓
    │   Reset button for next page: emit(state.copyWith(isButtonEnabled: false))
    │   ↓
    │   Navigate to next page (UserTypePage)
    │
    └─ Has errors?
        ↓
        Show errors: emit(state.copyWith(firstNameError: error1, lastNameError: error2))
        ↓
        BlocBuilder rebuilds UI
        ↓
        Red error text appears under fields
```

---

## 🎨 Reusable Widgets

### 1. SelectionCard
**Purpose**: Display selectable options with icon, title, and description

**Features**:
- Bold border when selected
- Radio button indicator
- Full tap area
- Reusable for any selection scenario

**Usage**:
```dart
SelectionCard(
  icon: AppIcons.homeIcon,
  title: OnboardingStrings.resident,
  description: OnboardingStrings.residentDescription,
  isSelected: state.selectedUserType == 'resident',
  onTap: () => cubit.onUserTypeChanged('resident'),
)
```

### 2. SelectionIndicator
**Purpose**: Radio button style indicator for selection state

**Features**:
- Circular shape with inner dot when selected
- Grey when unselected
- Dark grey when selected
- Extracted for reusability

**Usage**:
```dart
SelectionIndicator(isSelected: true)
```

### 3. ContactUsText
**Purpose**: "Have questions? Contact us" text with clickable link

**Features**:
- No parameters needed
- Underlined "Contact us" text
- TapGestureRecognizer for click handling
- Reusable across all onboarding pages

**Usage**:
```dart
ContactUsText()
```

### 4. TermsCheckbox
**Purpose**: Checkbox for terms and conditions acceptance

**Features**:
- Custom text support
- Value and callback binding
- Rounded corners
- Text wraps properly

**Usage**:
```dart
TermsCheckbox(
  text: OnboardingStrings.termsCheckboxText,
  value: cubit.termsAccepted,
  onChanged: (value) => cubit.onTermsChanged(value ?? false),
)
```

### 5. StepProgressIndicator
**Purpose**: Show progress through multi-step flow

**Features**:
- Horizontal bar with 8 steps (configurable)
- Current step highlighted in red
- Remaining steps in light red
- Smooth visual feedback

**Usage**:
```dart
StepProgressIndicator(currentStep: 1, totalSteps: 8)
```

### 6. ChooseCommunityField
**Purpose**: Clickable field for community selection

**Features**:
- Location icon
- Placeholder or selected community text
- Chevron right arrow
- Shadow effect around container
- Full tap area

**Usage**:
```dart
ChooseCommunityField(
  onTap: () => cubit.onChooseCommunityTapped(context: context),
  selectedCommunity: state.selectedCommunity,
)
```

---

## 🔌 Integration Points

### 1. Dependency Injection

Added to `lib/src/core/config/injection.dart`:

```dart
void setupDependencyInjection() {
  // ... existing code ...
  
  // Onboarding cubits (SINGLETONS - each shared across its flow pages)
  getIt.registerLazySingleton<GeneralOnboardingCubit>(
    () => GeneralOnboardingCubit(),
  );

  getIt.registerLazySingleton<ResidentOnboardingCubit>(
    () => ResidentOnboardingCubit(),
  );
}
```

### 2. Routes

Added to `lib/src/core/routes/names.dart`:

```dart
class RoutesName {
  // ... existing routes ...
  
  // Onboarding routes
  static const String onboardingStep1 = '/onboarding/step1';
  static const String onboardingStep2 = '/onboarding/step2';
  static const String onboardingResidentStep1 = '/onboarding/resident/step1';
}
```

Added to `lib/src/core/routes/router.dart`:

```dart
static Route<dynamic> generate(RouteSettings settings) {
  switch (settings.name) {
    // ... existing routes ...
    
    // General onboarding pages (Steps 1-2) use GeneralOnboardingCubit
    case RoutesName.onboardingStep1:
      return MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<GeneralOnboardingCubit>(),
          child: const UserNamePage(),
        ),
      );
    
    case RoutesName.onboardingStep2:
      return MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<GeneralOnboardingCubit>(),
          child: const UserTypePage(),
        ),
      );
    
    // Resident flow pages use ResidentOnboardingCubit
    case RoutesName.onboardingResidentStep1:
      // Extract user data from arguments
      final args = settings.arguments as Map<String, dynamic>?;
      final firstName = args?['firstName'] as String? ?? '';
      final lastName = args?['lastName'] as String? ?? '';
      
      // Initialize resident cubit with user data
      final residentCubit = getIt<ResidentOnboardingCubit>();
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        residentCubit.initializeWithUserData(
          firstName: firstName,
          lastName: lastName,
        );
      }
      
      return MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: residentCubit,
          child: const SetupAddressPage(),
        ),
      );
  }
}
```

### 3. Strings Constants

All UI strings centralized in `OnboardingStrings` class in `strings.dart`:

```dart
class OnboardingStrings {
  // Step 1: Personal Info
  static const String whatsYourName = "What's your name?";
  static const String firstName = 'First name';
  static const String firstNameHint = 'First name here';
  static const String lastName = 'Last name';
  static const String lastNameHint = 'Last name here';
  static const String termsCheckboxText = 'I agree to the Terms & Conditions and Privacy Policy';
  static const String alreadyHaveAccount = "Already have an account? ";
  static const String logIn = 'Log in';
  
  // Step 2: User Type
  static const String howWouldYouLikeToGetStarted = 'How would you like to get started?';
  static const String userTypeSubtitle = "Tell us if you're an owner or resident in one of the next communities, or you are here as a visitor.";
  static const String resident = 'Resident';
  static const String residentDescription = 'Owner or live in one of the communities';
  static const String visitor = 'Visitor';
  static const String visitorDescription = 'Here to visit someone or just passing by';
  static const String haveQuestions = 'Have questions? ';
  static const String contactUs = 'Contact us';
  
  // Resident Flow - Step 1: Setup Address
  static const String step1 = 'Step 1';
  static const String letsSetupYourAddress = "Let's setup your address";
  static const String setupAddressSubtitle = 'Choose your community to help us personalize your experience';
  static const String chooseYourCommunity = 'Choose your community';
  static const String next = 'Next';
  
  // Resident Flow - Step 2: Add Building & Unit
  static const String step2 = 'Step 2';
  static const String addYourHostBuildingAndUnitNumber = 'Add your host building and unit number';
  static const String addBuildingUnitSubtitle = 'This helps us identify your exact location';
  static const String unitNumberHint = 'Unit Number';
  static const String buildingNumberHint = 'Building Number';
  static const String back = 'Back';
  
  // Resident Flow - Step 3: Select Permit Plan
  static const String step3 = 'Step 3';
  static const String howLongWouldYouLikeAPermitFor = 'How long would you like a permit for?';
  static const String selectYourPermitFrequent = 'Select your permit frequent';
  static const String permitFrequent = 'Permit frequent';
  
  // Common
  static const String continueButton = 'Continue';
}
```

### 4. Text Styles

All onboarding headers use 28px font size:

```dart
// In AppTextStyles
static final urbanistFont28Grey800SemiBold1_2 = GoogleFonts.urbanist(
  fontSize: 28.sp,
  color: AppColor.grey800,
  fontWeight: FontWeight.w600,
  height: 1.2,
);
```

### 5. CommonButton Enhancement

Updated `CommonButton` to accept optional width parameter:

```dart
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;
  final double width; // NEW: Optional width parameter
  
  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.width = double.infinity, // NEW: Defaults to full width
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // NEW: Use width parameter
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        child: Text(text),
      ),
    );
  }
}
```

---

## ✅ What's Been Implemented

### Pages ✅

1. **UserNamePage (Step 1)** ✅
   - **Location**: `lib/src/features/onboarding/presentation/pages/user_name_page.dart`
   - **Features**:
     - First name and last name input fields
     - Real-time validation and error display
     - Terms & Conditions checkbox
     - "Already have account? Log in" toggle
     - Continue button (enabled only when form is valid)
   - **State Management**: Fully connected to `GeneralOnboardingCubit`

2. **UserTypePage (Step 2)** ✅
   - **Location**: `lib/src/features/onboarding/presentation/pages/user_type_page.dart`
   - **Features**:
     - 28px title header
     - Subtitle text explaining the options
     - Resident and Visitor selection cards with icons
     - Bold border and radio button indicator when selected
     - Clickable underlined "Contact us" link
     - Continue button (enabled when an option is selected)
   - **State Management**: Fully connected to `GeneralOnboardingCubit`

3. **SetupAddressPage (Resident Step 1)** ✅
   - **Location**: `lib/src/features/onboarding/presentation/pages/resident/setup_address_page.dart`
   - **Features**:
     - "Step 1" label (16px font, was incorrectly 28px, now fixed)
     - "Let's setup your address" title (28px)
     - Subtitle explaining the purpose
     - ChooseCommunityField with shadow effect
     - ContactUsText at bottom
     - StepProgressIndicator showing 1/8 steps
     - Next button with custom width (110.w) aligned to right
     - **Back button disabled** using `PopScope(canPop: false)` to prevent accidental navigation
   - **State Management**: Fully connected to `ResidentOnboardingCubit`

4. **AddBuildingUnitPage (Resident Step 2)** ✅
   - **Location**: `lib/src/features/onboarding/presentation/pages/resident/add_building_unit_page.dart`
   - **Features**:
     - "Step 2" label (28px font)
     - "Add your host building and unit number" title (28px)
     - Subtitle explaining the purpose
     - Unit Number field (rounded top corners, no title, no error message display)
     - Building Number field (rounded bottom corners, no title, no error message display)
     - **Number validation** - Fields show red border if non-numeric input is entered (no error text shown)
     - ContactUsText at bottom
     - StepProgressIndicator showing 2/8 steps
     - Back button (text button, 110.w) and Next button (110.w) aligned at bottom
     - Two fields are visually connected (appear as one container with top and bottom rounded)
     - **Back navigation cleanup** - Both "Back" button and system back button (via PopScope) trigger cleanup:
       - Clears unit number and building number controllers
       - Removes validation errors
       - Disables the Next button
       - Ensures clean state when returning to this page
   - **State Management**: Fully connected to `ResidentOnboardingCubit`
   - **Validation**: Uses `OnboardingValidators.validateNumber()` to ensure only digits are entered

5. **SelectPermitPlanPage (Resident Step 3)** ✅
   - **Location**: `lib/src/features/onboarding/presentation/pages/resident/select_permit_plan_page.dart`
   - **Features**:
     - "Step 3" label (28px font)
     - "How long would you like a permit for?" title (28px)
     - "Select your permit frequent" subtitle
     - "Permit frequent" label
     - Three permit plan options displayed as cards:
       - Weekly: $60
       - Monthly: $80
       - Yearly: $150
     - PermitPlanCard widgets with selection state (red border + checkmark when selected)
     - ContactUsText at bottom
     - StepProgressIndicator showing 3/8 steps
     - Back button (text button, 110.w) and Next button (110.w) aligned at bottom
     - **Back navigation cleanup** - Both "Back" button and system back button (via PopScope) trigger cleanup:
       - Clears selected permit plan
       - Disables the Next button
       - Ensures clean state when returning to this page
   - **State Management**: Fully connected to `ResidentOnboardingCubit`
   - **Data Model**: Uses `PermitPlanModel.availablePlans` for plan options

### State Management ✅

1. **GeneralOnboardingCubit** ✅
   - **Location**: `lib/src/features/onboarding/presentation/cubit/general/general_onboarding_cubit.dart`
   - **Implemented**:
     - TextEditingControllers for first/last name
     - Boolean for terms acceptance
     - User type selection state
     - Real-time button enable/disable logic
     - Field change handlers that clear errors
     - Validation on button press
     - Navigation between Steps 1-2 with button state reset
     - Data passing to flow-specific cubits via navigation arguments
     - Logging with AppLogger
     - Route name constants usage (no hardcoded strings)

2. **GeneralOnboardingState** ✅
   - **Location**: `lib/src/features/onboarding/presentation/cubit/general/general_onboarding_state.dart`
   - **Fields**:
     - `isButtonEnabled`: Auto-updates when form is valid, resets on navigation
     - `firstNameError`: Shows validation error (nullable)
     - `lastNameError`: Shows validation error (nullable)
     - `selectedUserType`: Tracks resident or visitor selection

3. **ResidentOnboardingCubit** ✅
   - **Location**: `lib/src/features/onboarding/presentation/cubit/resident/resident_onboarding_cubit.dart`
   - **Implemented**:
     - User data initialization from general onboarding
     - Community selection with search and filtering
     - Real-time button enable/disable logic
     - Community search query handling
     - Temporary selection in bottom sheet
     - Save community selection
     - Navigation through resident flow
     - Logging with AppLogger

4. **ResidentOnboardingState** ✅
   - **Location**: `lib/src/features/onboarding/presentation/cubit/resident/resident_onboarding_state.dart`
   - **Fields**:
     - `isButtonEnabled`: Auto-updates when community is selected
     - `selectedCommunity`: Tracks selected community name
     - `communitySearchQuery`: Current search query
     - `filteredCommunities`: Filtered list based on search
     - `tempSelectedCommunity`: Temporary selection in bottom sheet
     - `unitNumberError`: Validation error for unit number field (shows red border only)
     - `buildingNumberError`: Validation error for building number field (shows red border only)

### Domain Layer ✅

**OnboardingValidators** ✅
- **Location**: `lib/src/features/onboarding/domain/validators.dart`
- **Implemented Validators**:
  1. `validateName()` 
     - Checks minimum 2 characters
     - Letters only, allows spaces, hyphens, apostrophes
     - Proper error messages
  2. `validateNumber()` ✅
     - Ensures field is not empty
     - Validates that input contains only digits (0-9)
     - Used for unit number and building number fields
     - Returns error message (used for red border indication)

### Reusable Widgets ✅

1. **TermsCheckbox** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/terms_checkbox.dart`

2. **AccountTextToggle** ✅
   - Location: `lib/src/core/widgets/account_text_toggle.dart` 
   - Moved from auth feature for reusability

3. **SelectionCard** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/selection_card.dart`
   - Displays icon, title, and description
   - Shows bold border when selected
   - Radio button indicator via SelectionIndicator
   - Fully reusable

4. **SelectionIndicator** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/general/selection_indicator.dart`
   - Extracted from SelectionCard for reusability
   - Radio button style indicator

5. **ContactUsText** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/general/contact_us_text.dart`
   - No parameters needed
   - Underlined "Contact us" text
   - Reusable across pages

6. **StepProgressIndicator** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/general/step_progress_indicator.dart`
   - Shows 8 steps with current step highlighted
   - Red color for active steps
   - Light red for inactive steps

7. **ChooseCommunityField** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/resident/choose_community_field.dart`
   - Clickable field with location icon
   - Shows selected community or placeholder
   - Shadow effect around container
   - Chevron right arrow

8. **CommunitySelectionItem** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/resident/community_selection_item.dart`
   - Displays community name with selection indicator
   - Uses SelectionIndicator for consistent radio button design
   - Full tap area

9. **CommunitySelectionBottomSheet** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/resident/community_selection_bottom_sheet.dart`
   - 747.h height modal bottom sheet
   - SearchTextField for filtering communities
   - Scrollable community list
   - Save button enabled when community is selected
   - Connected to ResidentOnboardingCubit

10. **CommonTextButton** ✅
   - Location: `lib/src/core/widgets/common_text_button.dart`
   - Text-only button without background (commonly used for "Back" actions)
   - Optional width parameter (defaults to double.infinity)
   - Grey700 text color
   - Usage:
     ```dart
     CommonTextButton(
       text: OnboardingStrings.back,
       onPressed: () => Navigator.of(context).pop(),
       width: 110.w,
     )
     ```

11. **PermitPlanCard** ✅
   - Location: `lib/src/features/onboarding/presentation/widgets/resident/permit_plan_card.dart`
   - Displays permit plan option with period and price
   - Shows red border and checkmark icon when selected
   - Full tap area
   - Usage:
     ```dart
     PermitPlanCard(
       plan: PermitPlanModel(period: 'Weekly', price: 60, value: 'weekly'),
       isSelected: state.selectedPermitPlan == plan,
       onTap: () => cubit.onPermitPlanSelected(plan),
     )
     ```

### Widget Organization ✅

Created organized folder structure:
- `widgets/general/` - Reusable widgets across all onboarding flows
- `widgets/resident/` - Resident-specific widgets
- This keeps widgets clean and maintainable

### Routes ✅

- Added `onboardingStep1`, `onboardingStep2`, `onboardingResidentStep1` to `RoutesName`
- Configured routes in `AppRouter` with BlocProvider
- Used route name constants in cubit (no hardcoded strings)

---

## 🎓 Key Implementation Details

### 1. **Controller Ownership**
✅ Controllers are owned by the cubit (not the page) so they survive navigation and can be accessed across multiple steps.

### 2. **Button State Reset on Navigation**
✅ The `isButtonEnabled` state is reset to `false` whenever navigating to the next page. This ensures each new page starts with the button disabled until the user provides valid input or makes a selection.

**Implementation in cubit**:
```dart
void onContinuePersonalInfo({required BuildContext context}) {
  // ... validation logic ...
  if (firstNameError == null && lastNameError == null) {
    emit(state.copyWith(
      firstNameError: () => null,
      lastNameError: () => null,
      isButtonEnabled: false, // Reset button for next page
    ));
    Navigator.of(context).pushNamed(RoutesName.onboardingStep2);
  }
}
```

### 3. **Real-time vs On-Submit Validation**
- **Real-time**: Button enable/disable based on field presence
- **On-submit**: Show detailed error messages using domain validators

### 4. **Error Clearing Pattern**
When user types in a field → `onFieldChanged()` → clear that field's error → user sees instant feedback

### 5. **Nullable vs Non-nullable State**
- Errors are **nullable** (`String?`) - null = no error, string = error message
- Button state is **non-nullable** (`bool`) - always has a value

### 6. **Separation of Concerns**
- **Domain validators**: Pure validation logic (no Flutter dependencies)
- **Cubit**: Business logic and state management
- **Page**: Pure UI (stateless, no logic)

### 7. **Widget Reusability**
Extracted common UI patterns into separate widgets:
- `SelectionIndicator` extracted from `SelectionCard`
- `ContactUsText` used across multiple pages
- Organized in `general/` and `resident/` folders

### 8. **Typography Consistency**
All onboarding page headers use 28px font size (`urbanistFont28Grey800SemiBold1_2`)

### 9. **CommonButton Enhancement**
Added optional `width` parameter (defaults to `double.infinity`) to allow custom button widths without wrapping in SizedBox:
```dart
// Full width (default)
CommonButton(text: 'Continue', onPressed: () {})

// Custom width
CommonButton(text: 'Next', onPressed: () {}, width: 110.w)
```

### 11. **CustomTextField Enhancements**
Added flexible customization options to control the appearance:

**New Parameters:**
- `showError` (bool, default: true) - Control whether to display error messages
- `showTitle` (bool, default: true) - Control whether to display the title label
- `borderRadius` (BorderRadius?, default: BorderRadius.circular(10)) - Full control over border radius for all directions

**Usage Examples:**
```dart
// Standard text field with title and error
CustomTextField(
  title: 'First Name',
  hintText: 'Enter first name',
  controller: controller,
  validator: (_) => state.error,
  onChanged: (_) => cubit.onChanged(),
)

// Text field without title and error display (for connected fields)
CustomTextField(
  title: '',
  hintText: 'Unit Number',
  controller: controller,
  onChanged: (_) => cubit.onChanged(),
  showError: false,
  showTitle: false,
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(16.r),
    topRight: Radius.circular(16.r),
  ),
)

// Text field with validation but no error message (red border only)
CustomTextField(
  title: '',
  hintText: 'Unit Number',
  controller: controller,
  validator: (_) => state.unitNumberError, // Validator returns error for red border
  onChanged: (_) => cubit.onUnitNumberChanged(),
  showError: false, // Hide error message text, show only red border
  showTitle: false,
)

// Text field with custom border radius
CustomTextField(
  title: 'Search',
  hintText: 'Search here...',
  controller: controller,
  borderRadius: BorderRadius.circular(20.r),
)
```

**Benefits:**
- ✅ Create visually connected fields (like Unit Number + Building Number)
- ✅ Hide error messages for inline validation scenarios
- ✅ Show validation state through red border only (no error text)
- ✅ Hide title labels when not needed
- ✅ Full control over border styling for all directions
- ✅ Maintains backward compatibility (all parameters are optional)

### 12. **Data Models**

**PermitPlanModel** ✅
- **Location**: `lib/src/features/onboarding/data/models/permit_plan_model.dart`
- **Purpose**: Represents parking permit plan options (weekly, monthly, yearly)
- **Structure**:
  ```dart
  class PermitPlanModel extends Equatable {
    final String period;   // Display name: "Weekly", "Monthly", "Yearly"
    final int price;       // Price in dollars: 60, 80, 150
    final String value;    // Backend value: "weekly", "monthly", "yearly"
    
    // Static list of available plans
    static final List<PermitPlanModel> availablePlans = [
      PermitPlanModel(period: 'Weekly', price: 60, value: 'weekly'),
      PermitPlanModel(period: 'Monthly', price: 80, value: 'monthly'),
      PermitPlanModel(period: 'Yearly', price: 150, value: 'yearly'),
    ];
  }
  ```
- **Usage**: Used in `SelectPermitPlanPage` to display and select permit plan options

### 13. **Back Navigation Cleanup**

Implemented cleanup logic when navigating back from pages to ensure clean state:

**AddBuildingUnitPage Cleanup:**
```dart
// In ResidentOnboardingCubit
void clearBuildingUnitData() {
  unitNumberController.clear();
  buildingNumberController.clear();
  emit(state.copyWith(
    unitNumberError: () => null,
    buildingNumberError: () => null,
    isButtonEnabled: false,
  ));
  AppLogger.info('Resident Onboarding: Cleared building & unit data');
}

// In AddBuildingUnitPage
return PopScope(
  canPop: true,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) {
      cubit.clearBuildingUnitData();
    }
  },
  child: Scaffold(...),
);

// Back button handler
CommonTextButton(
  text: OnboardingStrings.back,
  onPressed: () {
    cubit.clearBuildingUnitData();
    Navigator.of(context).pop();
  },
  width: 110.w,
)
```

**SelectPermitPlanPage Cleanup:**
```dart
// In ResidentOnboardingCubit
void clearPermitPlanData() {
  emit(state.copyWith(
    selectedPermitPlan: () => null,  // Use callback to properly clear nullable field
    isButtonEnabled: false,
  ));
  AppLogger.info('Resident Onboarding: Cleared permit plan data');
}

// In SelectPermitPlanPage
return PopScope(
  canPop: true,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) {
      context.read<ResidentOnboardingCubit>().clearPermitPlanData();
    }
  },
  child: Scaffold(...),
);

// Back button handler
CommonTextButton(
  text: OnboardingStrings.back,
  onPressed: () {
    cubit.clearPermitPlanData();
    Navigator.of(context).pop();
  },
  width: 110.w,
)
```

**Benefits:**
- ✅ Clean state when user returns to the page
- ✅ Controllers are cleared (no stale data)
- ✅ Selections are reset (permit plan cleared)
- ✅ Validation errors are removed
- ✅ Button is disabled (requires fresh input)
- ✅ Consistent behavior for both back button types (text button and system back)
- ✅ Prevents confusion with partially filled forms

**Important Note on Nullable Fields:**
When clearing nullable fields in `copyWith`, use a callback function `() => null` instead of direct `null`:
```dart
// ❌ WRONG - Won't clear the field
emit(state.copyWith(selectedPermitPlan: null));

// ✅ CORRECT - Properly clears the field
emit(state.copyWith(selectedPermitPlan: () => null));
```

### 14. **Disable Back Button Pattern**

Some pages disable the system back button to prevent accidental navigation:

**Implementation:**
```dart
// In SetupAddressPage
return PopScope(
  canPop: false,  // Disable system back button
  child: Scaffold(...),
);
```

**Usage:**
- SetupAddressPage: Back button disabled (first step in resident flow)
- Future pages: Can be disabled for critical steps or payment flows

### 10. **Shadow Effects**
Added subtle shadow to `ChooseCommunityField` for elevation:
```dart
boxShadow: [
  BoxShadow(
    color: AppColor.grey400.withValues(alpha: 0.08),
    blurRadius: 16,
    offset: Offset(0, 3),
  ),
]
```

---

## 📝 Notes

### Why Separated Cubits?

The onboarding flow is split into **two singleton cubits**:

**GeneralOnboardingCubit:**
- Manages Steps 1-2 (user name and type selection)
- Single responsibility: collect basic user info
- Passes data to flow-specific cubits via navigation arguments

**ResidentOnboardingCubit:**
- Manages resident-specific flow (community, address, etc.)
- Receives user data via `initializeWithUserData()`
- Independent from general onboarding logic

**Benefits:**
- ✅ **Clear boundaries** - each cubit has single responsibility
- ✅ **No data redundancy** - data is passed, not duplicated
- ✅ **Easier maintenance** - changes to resident flow don't affect general flow
- ✅ **Scalability** - visitor flow can be added without touching resident code
- ✅ **Testability** - each cubit can be tested independently

### Why Separate Feature?

Onboarding is a separate feature (not part of auth) because:
1. **Auth = Authentication only** (login, signup, password reset)
2. **Onboarding = Data collection** (after authentication)
3. Can be triggered independently (e.g., "Complete Your Profile")
4. Can be updated/modified without touching auth code
5. Follows single responsibility principle

### Folder Organization

- **`pages/`** - Top-level pages only
- **`pages/resident/`** - Resident flow specific pages
- **`widgets/general/`** - Reusable across all flows
- **`widgets/resident/`** - Resident flow specific widgets

This keeps the codebase organized and makes it easy to add visitor flow later.

---

## 🚀 Next Steps

### Phase 1: Complete Resident Flow
- [x] ~~Implement community selection bottom sheet~~ ✅
- [x] ~~Add back button navigation~~ ✅
- [x] ~~Implement Step 3: Select Permit Plan~~ ✅
- [ ] Implement remaining resident onboarding steps (4-8)
- [ ] Add validators for additional fields (vehicle, etc.)

### Phase 2: Visitor Flow
- [ ] Implement visitor onboarding flow
- [ ] Add visitor-specific pages and widgets
- [ ] Handle visitor data submission

### Phase 3: Data Layer
- [ ] Implement `OnboardingData` model (fromJson, toJson, copyWith)
- [ ] Implement `OnboardingService.saveOnboardingData()`
- [ ] Implement `OnboardingService.isOnboardingCompleted()`
- [ ] Add database schema in Supabase

### Phase 4: Integration
- [ ] Update `LoginCubit` to check onboarding status
- [ ] Update `SignupCubit` to check onboarding status
- [ ] Update `AppRouter.getInitialRoute()` to check onboarding
- [ ] Test complete flow end-to-end

### Phase 5: Polish
- [ ] Add loading states
- [ ] Add error handling
- [ ] Add animations/transitions
- [ ] Implement contact us functionality
- [ ] Add back navigation handling

---

## 🎯 Recent Changes Summary

### UI/UX Improvements
1. ✅ Changed all onboarding headers from 34px to 28px
2. ✅ Fixed "Step 1" text to use 16px instead of 28px
3. ✅ Added underline to "Contact us" text
4. ✅ Added shadow effect to ChooseCommunityField
5. ✅ Added optional `width` parameter to CommonButton
6. ✅ Created AddBuildingUnitPage (Resident Step 2) with visually connected fields
7. ✅ Added Back button functionality using CommonTextButton

### Code Quality Improvements
1. ✅ Extracted `SelectionIndicator` from `SelectionCard` for reusability
2. ✅ Extracted `ContactUsText` as standalone widget with no parameters
3. ✅ Organized widgets into `general/` and `resident/` folders
4. ✅ Replaced hardcoded route strings with `RoutesName` constants
5. ✅ Added button state reset on navigation to ensure proper flow
6. ✅ Created `CommonTextButton` widget for text-only buttons (Back, Cancel, etc.)
7. ✅ Enhanced `CustomTextField` with `showError`, `showTitle`, and `borderRadius` parameters
8. ✅ Implemented visually connected text fields pattern (Unit + Building fields)
9. ✅ Added `validateNumber()` to OnboardingValidators for digit-only validation
10. ✅ Implemented red border validation (no error message) for unit and building number fields
11. ✅ Implemented back navigation cleanup for AddBuildingUnitPage:
   - Added `clearBuildingUnitData()` method to ResidentOnboardingCubit
   - Wrapped page with `PopScope` to intercept system back button
   - Both "Back" text button and system back button trigger cleanup
   - Clears controllers, errors, and resets button state
12. ✅ Disabled back button on SetupAddressPage using `PopScope(canPop: false)`
13. ✅ Created `PermitPlanModel` data model with static list of available plans
14. ✅ Created `PermitPlanCard` widget for displaying permit plan options
15. ✅ Implemented `SelectPermitPlanPage` (Resident Step 3) with permit plan selection
16. ✅ Implemented back navigation cleanup for SelectPermitPlanPage:
   - Added `clearPermitPlanData()` method to ResidentOnboardingCubit
   - Fixed nullable field clearing pattern using callback function `() => null`
   - Properly resets selectedPermitPlan and button state

### Architecture Improvements
1. ✅ Created clear separation between general and flow-specific widgets
2. ✅ Moved `AccountTextToggle` to core widgets for cross-feature reusability
3. ✅ Established consistent pattern for page structure
4. ✅ Implemented proper state management with button reset logic
5. ✅ **Split onboarding cubit into two separate cubits**:
   - `GeneralOnboardingCubit` for Steps 1-2 (user name and type)
   - `ResidentOnboardingCubit` for resident-specific flow
6. ✅ **Data passing via navigation arguments** instead of shared state
7. ✅ **No data redundancy** - each cubit owns only its relevant data
8. ✅ **Scalable architecture** - easy to add visitor flow without touching resident code
9. ✅ **Back navigation handling** with cleanup logic:
   - `PopScope` to intercept system back button
   - `clearBuildingUnitData()` to reset controllers and state
   - Consistent cleanup for both text button and system back button
10. ✅ **Strategic back button disabling** to prevent accidental navigation at critical flow points

---

**Created**: January 2024  
**Last Updated**: January 2024  
**Status**: Core structure implemented, resident flow in progress
