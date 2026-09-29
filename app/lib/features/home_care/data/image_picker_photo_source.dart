import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'photo_source.dart';

/// The platform's camera and photo library, through flutter.dev's own plugin
/// (home-care ADR-0003). It is asked for no more than a 2048 px long edge, so
/// what reaches the compressor is already a fraction of the sensor's size.
final class ImagePickerPhotoSource implements PhotoSource {
  ImagePickerPhotoSource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _largestEdge = 2048.0;

  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async {
    try {
      final file = await _picker.pickImage(
        source: switch (origin) {
          PhotoOrigin.camera => ImageSource.camera,
          PhotoOrigin.gallery => ImageSource.gallery,
        },
        maxWidth: _largestEdge,
        maxHeight: _largestEdge,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } on PlatformException catch (error) {
      AppLog.failure('photo picker', code: error.code, error: error);
      throw switch (error.code) {
        'camera_access_denied' || 'photo_access_denied' =>
          const HomeCareFailure(HomeCareProblem.cameraRefused),
        _ => UnknownFailure(error),
      };
    }
  }
}
