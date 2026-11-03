import 'dart:typed_data';

import '../../../shared/photos/compressed_photo.dart';
import '../model/frame_photo.dart';

abstract interface class FramePhotoStore {
  Future<List<FramePhoto>> list(String householdId);

  Future<Uint8List> bytes(String householdId, String photoId);

  Future<FramePhoto> add(
    String householdId,
    CompressedPhoto photo, {
    required String uploaderUid,
  });

  Future<void> remove(String householdId, String photoId);
}
