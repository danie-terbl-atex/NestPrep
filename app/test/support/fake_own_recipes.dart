import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/recipes/data/own_recipe_photo_store.dart';
import 'package:nestprep/features/recipes/data/own_recipe_repository.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_picker.dart';
import 'package:nestprep/features/recipes/model/own_recipe_save.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/photos/compressed_photo.dart';
import 'package:nestprep/shared/photos/photo_compressor.dart';

final class FakeOwnRecipeRepository implements OwnRecipeRepository {
  final saves =
      <({String householdId, String recipeId, OwnRecipeSave recipe})>[];
  final deleted = <String>[];
  AppFailure? failWith;
  Completer<void>? hold;

  @override
  Future<void> save({
    required String householdId,
    required String recipeId,
    required OwnRecipeSave recipe,
  }) async {
    saves.add((householdId: householdId, recipeId: recipeId, recipe: recipe));
    await hold?.future;
    if (failWith case final failure?) throw failure;
  }

  @override
  Future<void> delete({
    required String householdId,
    required String recipeId,
  }) async {
    await hold?.future;
    if (failWith case final failure?) throw failure;
    deleted.add(recipeId);
  }
}

final class FakeOwnRecipePhotoStore implements OwnRecipePhotoStore {
  final uploaded = <String>[];
  final uploaderUids = <String>{};
  final removed = <String>[];
  AppFailure? failUploadWith;
  AppFailure? failRemoveWith;

  /// Storage is create-only: a second upload to a stored path is refused.
  final stored = <String>{};

  @override
  Future<void> upload({
    required String path,
    required String uploaderUid,
    required Uint8List bytes,
  }) async {
    if (failUploadWith case final failure?) throw failure;
    if (!stored.add(path)) throw const PermissionDeniedFailure();
    uploaded.add(path);
    uploaderUids.add(uploaderUid);
  }

  @override
  Future<void> remove(String path) async {
    if (failRemoveWith case final failure?) throw failure;
    stored.remove(path);
    removed.add(path);
  }
}

final class FakeRecipePhotoPicker implements RecipePhotoPicker {
  List<Uint8List> picks = const [];
  AppFailure? failWith;
  final limits = <int>[];

  @override
  Future<List<Uint8List>> pick(
    RecipePhotoOrigin origin, {
    required int limit,
  }) async {
    limits.add(limit);
    if (failWith case final failure?) throw failure;
    return picks;
  }
}

final class FakeRecipePhotoCompressor implements PhotoCompressor {
  const FakeRecipePhotoCompressor([this.refuseWith]);

  final AppFailure? refuseWith;

  @override
  Future<CompressedPhoto> compress(Uint8List original) async {
    if (refuseWith case final failure?) throw failure;
    return CompressedPhoto(bytes: original, width: 4, height: 3);
  }
}
