import 'dart:typed_data';

import 'package:nestprep/features/nanny_hub/data/photo_picker.dart';
import 'package:nestprep/features/nanny_hub/data/photo_store.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Storage for the hub's photos, in memory.
final class FakePhotoStore implements PhotoStore {
  final objects = <String, Uint8List>{};
  final reads = <String>[];
  final removed = <String>[];
  AppFailure? failReadsWith;
  AppFailure? failUploadsWith;
  var _next = 0;

  @override
  String newPhotoId() => 'photo-${(_next++).toString().padLeft(4, '0')}';

  @override
  Future<void> upload({
    required String householdId,
    required String photoId,
    required String uploaderUid,
    required Uint8List jpeg,
  }) async {
    final failure = failUploadsWith;
    if (failure != null) throw failure;
    objects[photoId] = jpeg;
  }

  @override
  Future<Uint8List> read({
    required String householdId,
    required String photoId,
  }) async {
    reads.add(photoId);
    final failure = failReadsWith;
    if (failure != null) throw failure;
    final bytes = objects[photoId];
    if (bytes == null) throw const NotFoundFailure();
    return bytes;
  }

  @override
  Future<void> remove({
    required String householdId,
    required String photoId,
  }) async {
    removed.add(photoId);
    objects.remove(photoId);
  }
}

/// The camera and library, answering with whatever the test hands them.
final class FakePhotoPicker implements PhotoPicker {
  Uint8List? next;
  AppFailure? failWith;
  final asked = <PhotoSource>[];

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    asked.add(source);
    final failure = failWith;
    if (failure != null) throw failure;
    return next;
  }
}
