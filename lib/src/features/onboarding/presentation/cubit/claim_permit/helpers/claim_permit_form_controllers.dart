import 'package:flutter/material.dart';

/// Manages all text editing controllers for the claim permit flow
class ClaimPermitFormControllers {
  // Building & Unit controllers
  final TextEditingController unitNumber = TextEditingController();
  final TextEditingController buildingNumber = TextEditingController();

  // Vehicle controllers
  final TextEditingController plateNumber = TextEditingController();
  final TextEditingController vehicleMake = TextEditingController();
  final TextEditingController vehicleModel = TextEditingController();
  final TextEditingController vehicleColor = TextEditingController();
  final TextEditingController vehicleYear = TextEditingController();

  /// Check if building and unit fields have data
  bool hasBuildingUnitData() {
    return unitNumber.text.trim().isNotEmpty &&
        buildingNumber.text.trim().isNotEmpty;
  }

  /// Check if all vehicle fields have data
  bool hasVehicleData() {
    return plateNumber.text.trim().isNotEmpty &&
        vehicleMake.text.trim().isNotEmpty &&
        vehicleModel.text.trim().isNotEmpty &&
        vehicleColor.text.trim().isNotEmpty &&
        vehicleYear.text.trim().isNotEmpty;
  }

  /// Clear building and unit controllers
  void clearBuildingUnit() {
    unitNumber.clear();
    buildingNumber.clear();
  }

  /// Clear vehicle controllers
  void clearVehicle() {
    plateNumber.clear();
    vehicleMake.clear();
    vehicleModel.clear();
    vehicleColor.clear();
    vehicleYear.clear();
  }

  /// Add listeners to building/unit controllers
  void addBuildingUnitListeners(VoidCallback listener) {
    unitNumber.addListener(listener);
    buildingNumber.addListener(listener);
  }

  /// Add listeners to vehicle controllers
  void addVehicleListeners(VoidCallback listener) {
    plateNumber.addListener(listener);
    vehicleMake.addListener(listener);
    vehicleModel.addListener(listener);
    vehicleColor.addListener(listener);
    vehicleYear.addListener(listener);
  }

  /// Dispose all controllers
  void dispose() {
    unitNumber.dispose();
    buildingNumber.dispose();
    plateNumber.dispose();
    vehicleMake.dispose();
    vehicleModel.dispose();
    vehicleColor.dispose();
    vehicleYear.dispose();
  }
}
