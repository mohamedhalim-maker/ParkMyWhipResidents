import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/helpers/app_logger.dart';
import 'package:park_my_whip_residents/src/core/widgets/error_dialog.dart';

/// Service for handling file and image picking with validation
class ClaimPermitFilePickerService {
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  /// Pick an image from camera
  Future<File?> pickImageFromCamera(
    BuildContext context,
    Function(bool) setLoading,
  ) async {
    return _pickImage(ImageSource.camera, context, setLoading);
  }

  /// Pick an image from gallery
  Future<File?> pickImageFromGallery(
    BuildContext context,
    Function(bool) setLoading,
  ) async {
    return _pickImage(ImageSource.gallery, context, setLoading);
  }

  /// Pick an image from gallery or camera
  Future<File?> _pickImage(
    ImageSource source,
    BuildContext context,
    Function(bool) setLoading,
  ) async {
    try {
      setLoading(true);

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      setLoading(false);

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        if (!await _validateFileSize(file, context)) {
          return null;
        }

        AppLogger.info('Image picked: ${pickedFile.name}');
        return file;
      }

      return null;
    } catch (e) {
      setLoading(false);
      AppLogger.error('Error picking image: $e');

      if (context.mounted) {
        await showErrorDialog(
          context: context,
          title: ImagePickerStrings.error,
          message: ImagePickerStrings.failedToPickImage,
        );
      }

      return null;
    }
  }

  /// Pick a file (image or PDF) from files
  Future<File?> pickFile(
    BuildContext context,
    Function(bool) setLoading,
  ) async {
    try {
      setLoading(true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      setLoading(false);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        if (!await _validateFileSize(file, context)) {
          return null;
        }

        AppLogger.info('File picked: ${result.files.single.name}');
        return file;
      }

      return null;
    } catch (e) {
      setLoading(false);
      AppLogger.error('Error picking file: $e');

      if (context.mounted) {
        await showErrorDialog(
          context: context,
          title: ImagePickerStrings.error,
          message: ImagePickerStrings.failedToPickImage,
        );
      }

      return null;
    }
  }

  /// Validate file size (5 MB max)
  Future<bool> _validateFileSize(File file, BuildContext context) async {
    final fileSize = await file.length();

    if (fileSize > _maxFileSizeBytes) {
      if (context.mounted) {
        await showErrorDialog(
          context: context,
          title: ImagePickerStrings.fileTooLarge,
          message: ImagePickerStrings.fileSizeTooLargeMessage(
            fileSize / (1024 * 1024),
          ),
        );
      }
      return false;
    }

    return true;
  }

  /// Get file name from path
  String getFileName(String path) {
    return path.split('/').last;
  }

  /// Check if file is an image based on extension
  bool isImageFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png');
  }
}
