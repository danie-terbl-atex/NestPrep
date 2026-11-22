import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../list_scan/data/list_photo_picker.dart';
import '../model/recipe_snap.dart';
import 'recipe_snap_picker.dart';
import 'recipe_snap_pictures.dart';

final class DeviceRecipeSnapPicker implements RecipeSnapPicker {
  DeviceRecipeSnapPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<RecipeSnapPick> pick(
    ListPhotoSource source, {
    required int photoRoom,
    required int partRoom,
  }) async {
    final List<XFile> files;
    try {
      files = await _chosen(source, photoRoom);
    } on PlatformException catch (error) {
      AppLog.failure('recipe snap picker', code: error.code, error: error);
      throw const ListScanFailure(ListScanProblem.pickerUnavailable);
    }
    final snaps = <RecipeSnap>[];
    var room = partRoom;
    // Android's picker may hand back more than it was asked for.
    for (final file in files.take(photoRoom)) {
      final original = await file.readAsBytes();
      final left = room;
      final cut = await Isolate.run(
        () => RecipeSnapPictures.cut(original, partRoom: left),
      );
      switch (cut) {
        case RecipeSnapReady(:final snap):
          snaps.add(snap);
          room -= snap.parts.length;
        case RecipeSnapUnreadable():
          return RecipeSnapPick(
            snaps: snaps,
            problem: const RecipeImportFailure(
              RecipeImportProblem.photoUnreadable,
            ),
          );
        case RecipeSnapTooLong():
          return RecipeSnapPick(
            snaps: snaps,
            problem: const RecipeImportFailure(
              RecipeImportProblem.photosTooLong,
            ),
          );
      }
    }
    return RecipeSnapPick(snaps: snaps);
  }

  Future<List<XFile>> _chosen(ListPhotoSource source, int photoRoom) async {
    if (source == ListPhotoSource.photos && photoRoom > 1) {
      return _picker.pickMultiImage(
        limit: photoRoom,
        requestFullMetadata: false,
      );
    }
    final file = await _picker.pickImage(
      source: switch (source) {
        ListPhotoSource.camera => ImageSource.camera,
        ListPhotoSource.photos => ImageSource.gallery,
      },
      requestFullMetadata: false,
    );
    return [?file];
  }
}
