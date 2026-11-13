import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/list_scan/model/list_photo.dart';
import 'package:nestprep/features/recipes/data/recipe_drafter.dart';
import 'package:nestprep/features/recipes/data/recipe_image_fetcher.dart';
import 'package:nestprep/features/recipes/data/recipe_page_reader.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_draft_reading.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/model/recipe_page.dart';
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
  final photos = <ListPhoto>[];

  @override
  Future<RecipeDraftReading> fromPage({
    required String householdId,
    required RecipePage page,
  }) async {
    pages.add(page);
    return _answer();
  }

  @override
  Future<RecipeDraftReading> fromPhoto({
    required String householdId,
    required ListPhoto photo,
  }) async {
    photos.add(photo);
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
