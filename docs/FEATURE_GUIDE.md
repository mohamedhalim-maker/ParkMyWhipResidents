# Feature Development Guide

## Creating a New Feature

Follow this checklist when implementing a new feature:

### Step 1: Create Feature Directory Structure

```
lib/src/features/<feature_name>/
├── data/
│   ├── models/
│   │   └── <model_name>.dart
│   └── services/
│       └── <feature>_service.dart
├── domain/
│   └── validators.dart (if needed)
└── presentation/
    ├── cubit/
    │   ├── <feature>_cubit.dart
    │   └── <feature>_state.dart
    ├── pages/
    │   └── <feature>_page.dart
    └── widgets/
        └── <feature>_widget.dart
```

### Step 2: Create Data Model

**File**: `lib/src/features/<feature>/data/models/<model>.dart`

```dart
class Vehicle {
  final String id;
  final String userId;
  final String make;
  final String model;
  final String licensePlate;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.licensePlate,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory from JSON (Supabase response)
  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    make: json['make'] as String,
    model: json['model'] as String,
    licensePlate: json['license_plate'] as String,
    color: json['color'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  // To JSON for API requests
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'make': make,
    'model': model,
    'license_plate': licensePlate,
    'color': color,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // CopyWith for immutable updates
  Vehicle copyWith({
    String? id,
    String? userId,
    String? make,
    String? model,
    String? licensePlate,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Vehicle(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    make: make ?? this.make,
    model: model ?? this.model,
    licensePlate: licensePlate ?? this.licensePlate,
    color: color ?? this.color,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
```

### Step 3: Create Service

**File**: `lib/src/features/<feature>/data/services/<feature>_service.dart`

```dart
import 'dart:developer';
import 'package:park_my_whip_residents/src/features/vehicles/data/models/vehicle.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

class VehicleService {
  static const String _tableName = 'vehicles';

  /// Fetch all vehicles for a user
  Future<List<Vehicle>> getVehicles(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();
    } catch (e) {
      log('Error fetching vehicles: $e', name: 'VehicleService');
      rethrow;
    }
  }

  /// Create a new vehicle
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .insert(vehicle.toJson())
          .select()
          .single();

      return Vehicle.fromJson(response);
    } catch (e) {
      log('Error creating vehicle: $e', name: 'VehicleService');
      rethrow;
    }
  }

  /// Update a vehicle
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    try {
      final response = await SupabaseConfig.client
          .from(_tableName)
          .update(vehicle.toJson())
          .eq('id', vehicle.id)
          .select()
          .single();

      return Vehicle.fromJson(response);
    } catch (e) {
      log('Error updating vehicle: $e', name: 'VehicleService');
      rethrow;
    }
  }

  /// Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await SupabaseConfig.client
          .from(_tableName)
          .delete()
          .eq('id', vehicleId);
    } catch (e) {
      log('Error deleting vehicle: $e', name: 'VehicleService');
      rethrow;
    }
  }
}
```

### Step 4: Create State

**File**: `lib/src/features/<feature>/presentation/cubit/<feature>_state.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:park_my_whip_residents/src/features/vehicles/data/models/vehicle.dart';

class VehicleState extends Equatable {
  final bool isLoading;
  final List<Vehicle> vehicles;
  final String? error;
  final Vehicle? selectedVehicle;

  const VehicleState({
    this.isLoading = false,
    this.vehicles = const [],
    this.error,
    this.selectedVehicle,
  });

  VehicleState copyWith({
    bool? isLoading,
    List<Vehicle>? vehicles,
    String? error,
    Vehicle? selectedVehicle,
  }) => VehicleState(
    isLoading: isLoading ?? this.isLoading,
    vehicles: vehicles ?? this.vehicles,
    error: error,  // Allow null to clear error
    selectedVehicle: selectedVehicle ?? this.selectedVehicle,
  );

  @override
  List<Object?> get props => [isLoading, vehicles, error, selectedVehicle];
}
```

### Step 5: Create Cubit

**File**: `lib/src/features/<feature>/presentation/cubit/<feature>_cubit.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_my_whip_residents/src/core/networking/network_exceptions.dart';
import 'package:park_my_whip_residents/src/features/vehicles/data/models/vehicle.dart';
import 'package:park_my_whip_residents/src/features/vehicles/data/services/vehicle_service.dart';
import 'package:park_my_whip_residents/src/features/vehicles/presentation/cubit/vehicle_state.dart';

class VehicleCubit extends Cubit<VehicleState> {
  final VehicleService _vehicleService;
  final String _userId;

  // Form controllers (owned by cubit, disposed in close())
  final makeController = TextEditingController();
  final modelController = TextEditingController();
  final licensePlateController = TextEditingController();
  final colorController = TextEditingController();

  VehicleCubit({
    required VehicleService vehicleService,
    required String userId,
  })  : _vehicleService = vehicleService,
        _userId = userId,
        super(const VehicleState());

  /// Load all vehicles
  Future<void> loadVehicles() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final vehicles = await _vehicleService.getVehicles(_userId);
      emit(state.copyWith(isLoading: false, vehicles: vehicles));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: NetworkExceptions.getSupabaseExceptionMessage(e),
      ));
    }
  }

  /// Add a new vehicle
  Future<bool> addVehicle() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final vehicle = Vehicle(
        id: '', // Will be generated by Supabase
        userId: _userId,
        make: makeController.text.trim(),
        model: modelController.text.trim(),
        licensePlate: licensePlateController.text.trim(),
        color: colorController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final created = await _vehicleService.createVehicle(vehicle);
      emit(state.copyWith(
        isLoading: false,
        vehicles: [created, ...state.vehicles],
      ));
      _clearForm();
      return true;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: NetworkExceptions.getSupabaseExceptionMessage(e),
      ));
      return false;
    }
  }

  void _clearForm() {
    makeController.clear();
    modelController.clear();
    licensePlateController.clear();
    colorController.clear();
  }

  @override
  Future<void> close() {
    makeController.dispose();
    modelController.dispose();
    licensePlateController.dispose();
    colorController.dispose();
    return super.close();
  }
}
```

### Step 6: Create Page

**File**: `lib/src/features/<feature>/presentation/pages/<feature>_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';
import 'package:park_my_whip_residents/src/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:park_my_whip_residents/src/features/vehicles/presentation/cubit/vehicle_state.dart';

class VehicleListPage extends StatelessWidget {
  const VehicleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'My Vehicles'),
      body: BlocConsumer<VehicleCubit, VehicleState>(
        listener: (context, state) {
          // Handle side effects (navigation, snackbars)
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.vehicles.isEmpty) {
            return const VehicleEmptyState();
          }

          return VehicleListView(vehicles: state.vehicles);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVehicleSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddVehicleSheet(BuildContext context) {
    // Show bottom sheet for adding vehicle
  }
}

// Extract widgets as separate classes
class VehicleEmptyState extends StatelessWidget {
  const VehicleEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 64.sp),
          verticalSpace(16),
          Text('No vehicles yet', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class VehicleListView extends StatelessWidget {
  final List<Vehicle> vehicles;
  
  const VehicleListView({super.key, required this.vehicles});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: vehicles.length,
      itemBuilder: (context, index) => VehicleCard(vehicle: vehicles[index]),
    );
  }
}
```

### Step 7: Register Dependencies

**File**: `lib/src/core/config/injection.dart`

```dart
void setupDependencyInjection() {
  // ... existing registrations ...

  // Vehicle Feature
  getIt.registerLazySingleton<VehicleService>(() => VehicleService());
  
  getIt.registerFactory<VehicleCubit>(
    () => VehicleCubit(
      vehicleService: getIt<VehicleService>(),
      userId: getIt<AuthManager>().currentUser!.id,
    ),
  );
}
```

### Step 8: Add Routes

**File**: `lib/src/core/routes/names.dart`

```dart
class RoutesName {
  // ... existing routes ...
  static const String vehicleList = '/vehicles';
  static const String vehicleDetail = '/vehicles/detail';
  static const String addVehicle = '/vehicles/add';
}
```

**File**: `lib/src/core/routes/router.dart`

```dart
static Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    // ... existing routes ...
    
    case RoutesName.vehicleList:
      return MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<VehicleCubit>()..loadVehicles(),
          child: const VehicleListPage(),
        ),
      );
      
    // ...
  }
}
```

## Checklist Summary

- [ ] Create feature folder structure
- [ ] Create data model with `fromJson`, `toJson`, `copyWith`
- [ ] Create service with CRUD operations
- [ ] Create state class extending `Equatable`
- [ ] Create cubit with TextControllers, dispose in `close()`
- [ ] Create page as StatelessWidget with BlocBuilder
- [ ] Extract sub-widgets as separate classes (not functions)
- [ ] Register service and cubit in `injection.dart`
- [ ] Add route names and route configuration
- [ ] Use `NetworkExceptions` for error handling
- [ ] Use theme colors and text styles (never hardcode)
