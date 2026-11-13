import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'avatar_photo_picker.dart';

final class ImagePickerAvatarPhotoPicker implements AvatarPhotoPicker {
  ImagePickerAvatarPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(
    AvatarPhotoSource source, {
    bool facingUser = true,
  }) async {
    try {
      final file = await _picker.pickImage(
        source: switch (source) {
          AvatarPhotoSource.camera => ImageSource.camera,
          AvatarPhotoSource.library => ImageSource.gallery,
        },
        preferredCameraDevice: facingUser
            ? CameraDevice.front
            : CameraDevice.rear,
        requestFullMetadata: false,
      );
      return await file?.readAsBytes();
    } on PlatformException catch (error) {
      AppLog.failure('avatar photo picker', code: error.code, error: error);
      throw const AvatarFailure(AvatarProblem.pickerUnavailable);
    }
  }
}
