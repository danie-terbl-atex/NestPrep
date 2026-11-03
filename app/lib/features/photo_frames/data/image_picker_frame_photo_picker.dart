import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'frame_photo_picker.dart';

final class ImagePickerFramePhotoPicker implements FramePhotoPicker {
  ImagePickerFramePhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedPhoto>> pickMany({required int limit}) async {
    try {
      final files = await _picker.pickMultiImage(
        limit: limit < 2 ? null : limit,
        requestFullMetadata: false,
      );
      return [for (final file in files) () => _read(file)];
    } on PlatformException catch (error) {
      AppLog.failure('frame photo picker', code: error.code, error: error);
      throw const FramePhotoFailure(FramePhotoProblem.libraryUnavailable);
    }
  }

  static Future<Uint8List> _read(XFile file) async {
    try {
      return await file.readAsBytes();
    } on FileSystemException {
      throw const FramePhotoFailure(FramePhotoProblem.photoUnreadable);
    }
  }
}
