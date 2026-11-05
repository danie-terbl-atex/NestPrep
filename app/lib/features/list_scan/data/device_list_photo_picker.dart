import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/photos/jpeg_compressor.dart';
import '../model/list_photo.dart';
import 'list_photo_picker.dart';

/// `image_picker`, the platform's own camera and library screens. The photo
/// leaves through the one household photo pipeline (`ENG-01`) at a school
/// letter's sharpness — handwriting needs it — and without its GPS position.
final class DeviceListPhotoPicker implements ListPhotoPicker {
  DeviceListPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const compressor = JpegCompressor(
    maxBytes: ListPhoto.maxBytes,
    unreadable: ListScanFailure(ListScanProblem.listPhotoNotSupported),
    tooLarge: ListScanFailure(ListScanProblem.listPhotoTooLarge),
    maxEdge: 2200,
    jpegQuality: 82,
  );

  @override
  Future<ListPhoto?> pick(ListPhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: switch (source) {
          ListPhotoSource.camera => ImageSource.camera,
          ListPhotoSource.photos => ImageSource.gallery,
        },
        requestFullMetadata: false,
      );
      if (file == null) return null;
      final photo = await compressor.compress(await file.readAsBytes());
      return ListPhoto(photo.bytes);
    } on PlatformException catch (error) {
      AppLog.failure('list photo picker', code: error.code, error: error);
      throw const ListScanFailure(ListScanProblem.pickerUnavailable);
    }
  }
}
