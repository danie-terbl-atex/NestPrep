import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/list_scan/data/list_photo_picker.dart';
import 'package:nestprep/features/recipes/data/recipe_drafter.dart';
import 'package:nestprep/features/recipes/data/recipe_image_fetcher.dart';
import 'package:nestprep/features/recipes/data/recipe_page_reader.dart';
import 'package:nestprep/features/recipes/data/recipe_snap_picker.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_draft_reading.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/model/recipe_page.dart';
import 'package:nestprep/features/recipes/model/recipe_snap.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

const aBobotieLink = 'https://drizzleanddip.com/bobotie/';

const aBobotiePage = RecipePage(
  url: aBobotieLink,
  title: 'Bobotie',
  jsonLd: ['{"@type":"Recipe","name":"Bobotie"}'],
  text: '',
  imageUrls: ['https://drizzleanddip.com/bobotie.jpg'],
);

RecipeDraft aBobotieDraft({
  List<String> candidateImageUrls = const [],
  RecipeOrigin origin = RecipeOrigin.link,
  String? sourceUrl = aBobotieLink,
  String? sourceName = 'drizzleanddip.com',
  bool cutShort = false,
  int? servings = 6,
}) => RecipeDraft(
  name: 'Bobotie',
  summary: 'Spiced mince under a savoury custard.',
  placement: const {RecipeContext.dinner: RecipeCourse.main},
  ingredients: const [
    RecipeIngredient(name: 'Mince', quantity: 500, unit: 'g'),
  ],
  steps: const ['Bake it.'],
  servings: servings,
  candidateImageUrls: candidateImageUrls,
  origin: origin,
  sourceUrl: sourceUrl,
  sourceName: sourceName,
  cutShort: cutShort,
);

RecipeSnap aSnap({int parts = 1}) => RecipeSnap(
  parts: List.filled(parts, Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0])),
  thumbnail: _onePixel,
);

/// A one-pixel PNG, so a strip can draw it.
final _onePixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00, //
  0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

final class FakeRecipeSnapPicker implements RecipeSnapPicker {
  /// One new photo each time, unless a test says otherwise.
  RecipeSnapPick? next;
  AppFailure? failWith;
  Completer<void>? gate;
  final asked = <({ListPhotoSource source, int photoRoom, int partRoom})>[];

  @override
  Future<RecipeSnapPick> pick(
    ListPhotoSource source, {
    required int photoRoom,
    required int partRoom,
  }) async {
    asked.add((source: source, photoRoom: photoRoom, partRoom: partRoom));
    await gate?.future;
    if (failWith case final failure?) throw failure;
    return next ?? RecipeSnapPick(snaps: [aSnap()]);
  }
}

final class FakeRecipePageReader implements RecipePageReader {
  RecipePage page = aBobotiePage;
  AppFailure? failWith;
  Completer<void>? gate;
  final asked = <String>[];

  @override
  Future<RecipePage> read(String url) async {
    asked.add(url);
    await gate?.future;
    if (failWith case final failure?) throw failure;
    return page;
  }
}

final class FakeRecipeDrafter implements RecipeDrafter {
  RecipeDraftReading reading = RecipeDraftReading(
    draft: aBobotieDraft(),
    callsLeft: 99,
  );
  AppFailure? failWith;
  Completer<void>? gate;
  final pages = <RecipePage>[];
  final photos = <List<RecipeSnap>>[];

  @override
  Future<RecipeDraftReading> fromPage({
    required String householdId,
    required RecipePage page,
  }) async {
    pages.add(page);
    return _answer();
  }

  @override
  Future<RecipeDraftReading> fromPhotos({
    required String householdId,
    required List<RecipeSnap> photos,
  }) async {
    this.photos.add(List.of(photos));
    return _answer();
  }

  Future<RecipeDraftReading> _answer() async {
    await gate?.future;
    if (failWith case final failure?) throw failure;
    return reading;
  }
}

final class FakeRecipeImageFetcher implements RecipeImageFetcher {
  FakeRecipeImageFetcher([this.answers = const {}]);

  final Map<String, Uint8List?> answers;
  final asked = <String>[];
  Completer<void>? gate;

  @override
  Future<Uint8List?> fetch(String url) async {
    asked.add(url);
    await gate?.future;
    return answers[url];
  }
}
