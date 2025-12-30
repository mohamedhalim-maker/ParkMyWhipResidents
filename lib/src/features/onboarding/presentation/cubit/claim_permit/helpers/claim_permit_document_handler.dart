import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/helpers/claim_permit_file_picker_service.dart';

/// Enum for document types
enum DocumentType {
  license,
  registration,
  insurance,
}

/// Handles document upload UI and file selection for claim permit
class ClaimPermitDocumentHandler {
  final ClaimPermitFilePickerService _filePickerService;

  ClaimPermitDocumentHandler(this._filePickerService);

  /// Show image source bottom sheet for license/registration
  Future<File?> showImageSourcePicker({
    required BuildContext context,
    required Function(bool) setLoading,
  }) async {
    final completer = Completer<File?>();
    bool picked = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                picked = true;
                Navigator.pop(sheetContext);
                final file = await _filePickerService.pickImageFromCamera(
                  context,
                  setLoading,
                );
                completer.complete(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                picked = true;
                Navigator.pop(sheetContext);
                final file = await _filePickerService.pickImageFromGallery(
                  context,
                  setLoading,
                );
                completer.complete(file);
              },
            ),
          ],
        ),
      ),
    );

    // If bottom sheet was dismissed without selection, complete with null
    if (!picked) {
      completer.complete(null);
    }

    return completer.future;
  }

  /// Show bottom sheet for insurance (camera/gallery/file)
  Future<({File? file, bool isImage})> showInsurancePicker({
    required BuildContext context,
    required Function(bool) setLoading,
  }) async {
    final completer = Completer<({File? file, bool isImage})>();
    bool picked = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose File Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                picked = true;
                Navigator.pop(context);
                final file = await _filePickerService.pickImageFromCamera(
                  context,
                  setLoading,
                );
                completer.complete((file: file, isImage: true));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                picked = true;
                Navigator.pop(context);
                final file = await _filePickerService.pickImageFromGallery(
                  context,
                  setLoading,
                );
                completer.complete((file: file, isImage: true));
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Files (PDF, JPG, PNG)'),
              onTap: () async {
                picked = true;
                Navigator.pop(context);
                final file = await _filePickerService.pickFile(
                  context,
                  setLoading,
                );
                bool isImage = true;
                if (file != null) {
                  final fileName = _filePickerService.getFileName(file.path);
                  isImage = _filePickerService.isImageFile(fileName);
                }
                completer.complete((file: file, isImage: isImage));
              },
            ),
          ],
        ),
      ),
    );

    // If bottom sheet was dismissed without selection, complete with null
    if (!picked) {
      completer.complete((file: null, isImage: true));
    }

    return completer.future;
  }
}
