# Onboarding Feature - Complete Documentation

## 📋 Overview

The onboarding feature collects essential user information after successful authentication. This is a **multi-step flow** that guides users through providing personal details and determining their user type (Resident or Visitor). The resident flow includes **6 completed steps**: user info, user type, community selection, building/unit, permit plan, vehicle information, driving license upload, and vehicle registration upload.

## 🏗️ Architecture

This feature follows **Clean Architecture** with clear separation of concerns:
- **Data Layer**: Models (`OnboardingData`, `PermitPlanModel`) and services
- **Domain Layer**: 6 validation functions (pure logic, no Flutter dependencies)
- **Presentation Layer**: 2 singleton cubits, 8 pages, 14 reusable widgets

### Directory Structure

```
lib/src/features/onboarding/
├── data/
│   ├── models/
│   │   ├── onboarding_data_model.dart        # Aggregated onboarding data (TODO)
│   │   └── permit_plan_model.dart            # ✅ Permit plan (Weekly/Monthly/Yearly)
│   └── services/
│       └── onboarding_service.dart           # Save to Supabase (TODO)
│
├── domain/
│   └── validators.dart                       # ✅ 6 validators (name, number, plate, color, year)
│
└── presentation/
    ├── cubit/
    │   ├── general/                          # ✅ General flow (Steps 1-2)
    │   │   ├── general_onboarding_cubit.dart # User name + user type logic
    │   │   └── general_onboarding_state.dart # 4 fields
    │   └── resident/                         # ✅ Resident flow (Steps 1-6)
    │       ├── resident_onboarding_cubit.dart # All resident steps
    │       └── resident_onboarding_state.dart # 18 fields
    │
    ├── pages/                                # ✅ 8 pages
    │   ├── user_name_page.dart               # Step 1: First/Last name
    │   ├── user_type_page.dart               # Step 2: Resident/Visitor
    │   └── resident/
    │       ├── setup_address_page.dart       # Resident Step 1: Community
    │       ├── add_building_unit_page.dart   # Resident Step 2: Unit + Building
    │       ├── select_permit_plan_page.dart  # Resident Step 3: Weekly/Monthly/Yearly
    │       ├── add_vehicle_info_page.dart    # Resident Step 4: Vehicle (5 fields)
    │       ├── upload_driving_license_page.dart      # Resident Step 5: License image
    │       └── upload_vehicle_registration_page.dart # Resident Step 6: Registration image
    │
    └── widgets/                              # ✅ 14 widgets
        ├── selection_card.dart
        ├── terms_checkbox.dart
        ├── general/                          # 3 widgets
        │   ├── contact_us_text.dart
        │   ├── selection_indicator.dart
        │   └── step_progress_indicator.dart
        └── resident/                         # 8 widgets
            ├── choose_community_field.dart
            ├── community_selection_item.dart
            ├── community_selection_bottom_sheet.dart
            ├── permit_plan_card.dart
            ├── vehicle_info_header.dart
            ├── vehicle_info_form.dart
            └── image_upload_widget.dart
```

---

## 🔄 State Management

### Two Singleton Cubits

**Why separated?**
- ✅ Clear boundaries between general and flow-specific logic
- ✅ No data redundancy (passed via navigation arguments)
- ✅ Easier maintenance (each cubit = single responsibility)
- ✅ Scalability (add visitor flow without touching resident code)

### GeneralOnboardingCubit (Steps 1-2)

**Controllers**: firstNameController, lastNameController  
**State**: 4 fields (isButtonEnabled, firstNameError, lastNameError, selectedUserType)

**Key Methods**:
- `onFirstNameChanged()` - Clear error on input
- `onLastNameChanged()` - Clear error on input
- `onTermsChanged(bool)` - Update terms acceptance
- `onContinuePersonalInfo()` - Validate + navigate to Step 2
- `onUserTypeChanged(String)` - Select resident/visitor
- `onContinueUserType()` - Pass data to resident/visitor flow

### ResidentOnboardingCubit (Steps 1-6+)

**Controllers**: 7 total (unitNumber, buildingNumber, plateNumber, vehicleMake, vehicleModel, vehicleColor, vehicleYear)  
**State**: 18 fields (button, community search, unit/building errors, permit plan, vehicle errors, form visibility, license image/filename, registration image/filename)

**Key Methods by Step**:

**Step 1 - Community**:
- `initializeWithUserData()` - Receive firstName, lastName
- `onChooseCommunityTapped()` - Show bottom sheet
- `onCommunitySearchChanged()` - Filter communities
- `onTempCommunitySelected()` - Temp selection in sheet
- `onCommunitySaved()` - Save selection
- `onContinueSetupAddress()` - Navigate to Step 2

**Step 2 - Building & Unit**:
- `onUnitNumberChanged()` - Clear error
- `onBuildingNumberChanged()` - Clear error
- `onContinueAddBuildingUnit()` - Validate + navigate to Step 3
- `clearBuildingUnitData()` - Back navigation cleanup

**Step 3 - Permit Plan**:
- `onPermitPlanSelected()` - Select plan
- `onContinueSelectPermitPlan()` - Navigate to Step 4
- `clearPermitPlanData()` - Back navigation cleanup

**Step 4 - Vehicle**:
- `onVehicleHeaderTapped()` - Show form
- `onPlateNumberChanged()` - Clear error
- `onVehicleMakeChanged()` - Clear error
- `onVehicleModelChanged()` - Clear error
- `onVehicleColorChanged()` - Clear error
- `onVehicleYearChanged()` - Clear error
- `onContinueAddVehicleInfo()` - Validate all fields
- `backFromVehicleInfo()` - Smart back (hide form OR navigate)
- `clearVehicleData()` - Clear all vehicle fields

**Step 5 - License Upload**:
- `pickImageFromCamera()` - Pick from camera
- `pickImageFromGallery()` - Pick from gallery
- `pickImage()` - Generic picker with validation
- `setLicenseImage()` - Set image and filename
- `removeLicenseImage()` - Remove license
- `onContinueUploadLicense()` - Navigate to Step 6
- `clearLicenseData()` - Back navigation cleanup

**Step 6 - Registration Upload**:
- `setRegistrationImage()` - Set image and filename
- `removeRegistrationImage()` - Remove registration
- `onContinueUploadRegistration()` - Navigate to next step
- `clearRegistrationData()` - Back navigation cleanup

---

## ✅ Completed Features

### Pages (8/8) ✅

| Step | Page | Features | State Management |
|------|------|----------|------------------|
| **1** | UserNamePage | First/Last name + Terms checkbox | GeneralOnboardingCubit |
| **2** | UserTypePage | Resident/Visitor selection | GeneralOnboardingCubit |
| **R1** | SetupAddressPage | Community search + selection | ResidentOnboardingCubit |
| **R2** | AddBuildingUnitPage | Unit + Building (connected fields) | ResidentOnboardingCubit |
| **R3** | SelectPermitPlanPage | Weekly/Monthly/Yearly plans | ResidentOnboardingCubit |
| **R4** | AddVehicleInfoPage | Plate/Make/Model/Color/Year | ResidentOnboardingCubit |
| **R5** | UploadDrivingLicensePage | License image upload | ResidentOnboardingCubit |
| **R6** | UploadVehicleRegistrationPage | Vehicle registration image upload | ResidentOnboardingCubit |

### Validators (6/6) ✅

| Validator | Rules | Used For |
|-----------|-------|----------|
| `validateName()` | 2+ chars, letters only | First/Last name |
| `validateNumber()` | Digits only (0-9) | Unit/Building numbers |
| `validatePlateNumber()` | 2-8 alphanumeric, UK format | Plate number |
| `validateVehicleField()` | Min 2 chars | Make, Model |
| `validateVehicleColor()` | Min 3 chars, letters | Color |
| `validateVehicleYear()` | 1980-current year | Year |

### Widgets (14/14) ✅

**General (5)**:
1. TermsCheckbox
2. AccountTextToggle  
3. SelectionCard
4. SelectionIndicator
5. ContactUsText

**Resident (8)**:
6. StepProgressIndicator (X/8 steps)
7. ChooseCommunityField (shadow effect)
8. CommunitySelectionItem
9. CommunitySelectionBottomSheet (search + list)
10. PermitPlanCard (price + period)
11. VehicleInfoHeader (+ icon)
12. VehicleInfoForm (5 fields)
13. LicenseUploadWidget (2 states: empty + uploaded)

**Core (1)**:
14. CommonTextButton (Back actions)

---

## 🎯 Recent Updates

### Step 6 Complete ✅

**UploadVehicleRegistrationPage** - Vehicle registration image upload with camera/gallery picker

**Features**:
- Empty state: imageIcon (red container) + "Take Photo or Upload" + forward arrow
- Uploaded state: Image preview + document icon (red container) + filename + close icon
- Image source selection: Camera or Gallery via bottom sheet
- Image quality optimization (85%, max 1920x1920)
- File size validation (5MB limit with error dialog)
- Remove uploaded image
- Max file size text (5MB)
- Loading state during image picking
- Error handling with dialogs

**Reused Widget**:
- ImageUploadWidget (same widget as license upload)

**State Updates**:
- registrationImage (File?)
- registrationFileName (String?)

**Cubit Methods**:
- setRegistrationImage() - Set image and filename
- removeRegistrationImage() - Clear registration data
- onContinueUploadRegistration() - Navigate to next step
- clearRegistrationData() - Back navigation cleanup

**Integration**:
- Uses same `pickImageFromCamera()` and `pickImageFromGallery()` methods
- Leverages existing `ImageSourceBottomSheet` widget
- Reuses `ImageUploadWidget` for consistent UI/UX
- Same error handling patterns as license upload

**Navigation Flow**:
- From: Upload Driving License (Step 5)
- To: Next step (TBD)

---

## 🎓 Advanced Patterns

### 1. Smart Back Navigation (Step 4)

**Problem**: User presses back → loses permit plan selection

**Solution**: Conditional navigation based on UI state

```dart
bool backFromVehicleInfo() {
  if (state.showVehicleForm) {
    // Form visible: hide it, clear data, STAY on page
    clearVehicleData();
    emit(state.copyWith(showVehicleForm: false));
    return false;  // Don't navigate
  } else {
    // Header visible: navigate to previous page
    emit(state.copyWith(isButtonEnabled: true));
    return true;  // Navigate back
  }
}

// In AddVehicleInfoPage
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (!didPop) {
      final shouldNavigate = cubit.backFromVehicleInfo();
      if (shouldNavigate) Navigator.of(context).pop();
    }
  },
  child: Scaffold(...),
)
```

**Result**: Form visible? Hide form. Header visible? Go back. ✅

### 2. Back Navigation Cleanup

**Problem**: User goes back → returns → sees stale data

**Solution**: Clear controllers + reset state on back

```dart
void clearBuildingUnitData() {
  unitNumberController.clear();
  buildingNumberController.clear();
  emit(state.copyWith(
    unitNumberError: () => null,
    buildingNumberError: () => null,
    isButtonEnabled: false,
  ));
}

PopScope(
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) cubit.clearBuildingUnitData();
  },
  child: Scaffold(...),
)
```

**Applied to**: Step 2 (Building/Unit), Step 3 (Permit Plan), Step 4 (Vehicle)

### 3. Nullable Field Clearing

**Problem**: `copyWith(field: null)` doesn't clear nullable fields

**Solution**: Use callback `() => null`

```dart
// ❌ WRONG
emit(state.copyWith(selectedPermitPlan: null));

// ✅ CORRECT
emit(state.copyWith(selectedPermitPlan: () => null));
```

### 4. Dynamic Year Dropdown

**Problem**: Hardcoded years (1980-2024) become outdated

**Solution**: Generate dynamically

```dart
final currentYear = DateTime.now().year;
final years = List.generate(
  currentYear - 1980 + 1,
  (index) => (currentYear - index).toString(),
);

DropdownButtonFormField<String>(
  items: years.map((year) => DropdownMenuItem(
    value: year,
    child: Text(year),
  )).toList(),
  ...
)
```

**Result**: Always shows 1980 to current year ✅

### 5. Visually Connected Fields

**Problem**: Unit + Building should look like ONE container

**Solution**: Custom borderRadius on each field

```dart
// Top field: rounded top only
CustomTextField(
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(16.r),
    topRight: Radius.circular(16.r),
  ),
  showError: false,
  showTitle: false,
)

// Bottom field: rounded bottom only
CustomTextField(
  borderRadius: BorderRadius.only(
    bottomLeft: Radius.circular(16.r),
    bottomRight: Radius.circular(16.r),
  ),
  showError: false,
  showTitle: false,
)
```

**Result**: Looks like one container with divider ✅

### 6. Two-State UI Toggle

**Problem**: Need different UI for empty vs filled state

**Solution**: Use boolean in state

```dart
// In ResidentOnboardingState
final bool showVehicleForm;

// In AddVehicleInfoPage
Visibility(
  visible: !state.showVehicleForm,
  child: VehicleInfoHeader(...),  // + icon
)
Visibility(
  visible: state.showVehicleForm,
  child: VehicleInfoForm(...),    // 5 fields
)
```

**Result**: Click header → show form. Press back → hide form. ✅

### 7. CustomTextField Enhancements

**New Parameters**:
- `showError` (default: true) - Show error text or just red border
- `showTitle` (default: true) - Show title label or hide
- `borderRadius` (default: 10) - Custom border radius

**Use Cases**:
- **Connected fields**: No title, no error text, custom borders (Unit + Building)
- **Inline validation**: Red border only, no error message (just visual feedback)
- **Custom styling**: Any border radius for unique designs

```dart
// Connected field with red border validation
CustomTextField(
  validator: (_) => state.unitNumberError,  // Returns error → red border
  showError: false,  // Don't show error text
  showTitle: false,  // Don't show title
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(16.r),
    topRight: Radius.circular(16.r),
  ),
)
```

---

## 🚀 Next Steps

### Phase 1: Resident Flow Completion
- [x] Step 1: Community ✅
- [x] Step 2: Building/Unit ✅
- [x] Step 3: Permit Plan ✅
- [x] Step 4: Vehicle Info ✅
- [x] Step 5: Upload License ✅
- [x] Step 6: Upload Vehicle Registration ✅
- [ ] Steps 7-8: TBD
- [ ] Final submission

### Phase 2: Visitor Flow
- [ ] Visitor pages
- [ ] Visitor cubit
- [ ] Visitor data submission

### Phase 3: Data Layer
- [ ] OnboardingData model
- [ ] OnboardingService implementation
- [ ] Supabase integration

### Phase 4: Integration
- [ ] Check onboarding after auth
- [ ] Route to onboarding if incomplete
- [ ] Route to dashboard if complete

### Phase 5: Polish
- [ ] Loading states
- [ ] Error handling
- [ ] Animations
- [ ] Contact us functionality

---

## 📊 Statistics

**Components**: 36 total
- Pages: 8 (2 general + 6 resident)
- Cubits: 2 (singleton)
- States: 2 (22 total fields: 4 general + 18 resident)
- Validators: 6
- Widgets: 14 (5 general + 8 resident + 1 core)
- Routes: 8
- Controllers: 7

**Lines of Code**: ~3200+
- Pages: ~950
- Cubits: ~650
- Widgets: ~1000
- Validators: ~160
- Models: ~100

---

## 🗂️ Previous Updates

### Step 5 Complete ✅

**UploadDrivingLicensePage** - License image upload with camera/gallery picker

**Features**:
- Empty state: imageIcon (red container) + "Take Photo or Upload" + forward arrow
- Uploaded state: Image preview + document icon (red container) + filename + close icon
- Image source selection: Camera or Gallery via bottom sheet
- Image quality optimization (85%, max 1920x1920)
- File size validation (5MB limit with error dialog)
- Remove uploaded image
- Max file size text (5MB)
- Loading state during image picking
- Error handling with dialogs

**New Widget**:
- ImageUploadWidget (reusable, 2 states with loading support)

**State Updates**:
- licenseImage (File?)
- licenseFileName (String?)
- isLoadingImage (bool)

**Cubit Methods**:
- pickImageFromCamera() - Pick from camera with ImagePicker
- pickImageFromGallery() - Pick from gallery with ImagePicker
- pickImage() - Generic picker with size validation & error handling
- setLicenseImage() - Set image and filename
- removeLicenseImage() - Clear license data
- onContinueUploadLicense() - Navigate to next step
- clearLicenseData() - Back navigation cleanup

**Integration**:
- Uses `image_picker` package for cross-platform image selection
- Leverages `ImageSourceBottomSheet` widget for source selection
- Automatic permission handling via image_picker plugin
- Error dialogs using `showErrorDialog` from core widgets

---

### Step 4 Complete ✅

**AddVehicleInfoPage** - Two-state UI with smart back navigation

**Features**:
- Header view: + icon → tap to show form
- Form view: 5 fields (Plate, Make, Model, Color, Year dropdown)
- Smart back: hide form OR navigate (prevents permit plan loss)
- Year dropdown: 1980 to current year (dynamic)
- 5 validators for vehicle fields

**New Widgets**:
- VehicleInfoHeader (clickable + icon)
- VehicleInfoForm (5 fields with validation)

**New Validators**:
- validatePlateNumber() - UK format
- validateVehicleField() - Generic
- validateVehicleColor() - Letters only
- validateVehicleYear() - 1980-current

**State Updates**:
- 5 vehicle error fields
- showVehicleForm toggle
- 5 vehicle controllers

**Cubit Methods**:
- backFromVehicleInfo() - Smart navigation
- clearVehicleData() - Clear all fields
- 5 field change handlers

---

## 🔍 Quick Reference

### User Flow

```
Login/Signup → Check onboarding_completed
    ↓ false
UserNamePage (Step 1) → First/Last + Terms
    ↓
UserTypePage (Step 2) → Resident/Visitor
    ↓ resident
SetupAddressPage (R1) → Community selection
    ↓
AddBuildingUnitPage (R2) → Unit + Building
    ↓
SelectPermitPlanPage (R3) → Weekly/Monthly/Yearly
    ↓
AddVehicleInfoPage (R4) → Plate/Make/Model/Color/Year
    ↓
UploadDrivingLicensePage (R5) → License image upload
    ↓
UploadVehicleRegistrationPage (R6) → Vehicle registration image upload
    ↓
[Steps 7-8 TBD]
    ↓
Submit → Dashboard
```

### Data Flow

```
GeneralOnboardingCubit:
  firstName, lastName → Navigate with arguments →
  
ResidentOnboardingCubit:
  initializeWithUserData(firstName, lastName)
  ↓
  Step 1: selectedCommunity
  ↓
  Step 2: unitNumber, buildingNumber
  ↓
  Step 3: selectedPermitPlan
  ↓
  Step 4: plateNumber, make, model, color, year
  ↓
  Step 5: licenseImage, licenseFileName
  ↓
  Step 6: registrationImage, registrationFileName
  ↓
  submitResidentOnboarding() (TODO)
```

---

**Created**: January 2024  
**Last Updated**: January 2024  
**Status**: Resident flow Step 6 complete ✅ (6/8 steps done)
