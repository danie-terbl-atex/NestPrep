import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'photo_picker.dart';

/// `image_picker` — the platform's own camera and library screens, so the app
/// asks for no photo permission of its own on Android and uses the system
/// picker on iOS (nanny-hub ADR-0003). Compression is the shared `JpegCompressor`'s, so
/// it is the same on both platforms.
final class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: switch (source) {
          PhotoSource.camera => ImageSource.camera,
          PhotoSource.library => ImageSource.gallery,
        },
        requestFullMetadata: false,
      );
      return await file?.readAsBytes();
    } on PlatformException catch (error) {
      AppLog.failure('photo picker', code: error.code, error: error);
      throw const NannyHubFailure(NannyHubProblem.cameraUnavailable);
    }
  }
}
