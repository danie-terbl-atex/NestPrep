import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../../../shared/state/action_failure.dart';
import '../../family_profiles/model/allergen.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../data/own_recipe_photo_store.dart';
import '../data/own_recipe_repository.dart';
import '../data/recipe_photo_picker.dart';
import '../data/recipe_photo_source.dart';
import '../model/own_recipe_ids.dart';
import '../model/own_recipe_photo_paths.dart';
import '../model/own_recipe_save.dart';
import '../model/recipe.dart';
import '../model/recipe_draft.dart';
import '../model/recipe_form.dart';
import '../model/recipe_meal_lines.dart';
import '../model/recipe_photo_cuts.dart';
import '../model/recipe_scale.dart';
import 'recipe_photo_intake.dart';

final class RecipeBuilderController extends ChangeNotifier
    with ActionFailureHolder {
  RecipeBuilderController({
    required this._ownRecipes,
    required this._photoStore,
    required this._photoPicker,
    required this._photoIntake,
    required this._photoSource,
    required MealRepository mealRepository,
    required this.householdId,
    required this.viewerUid,
    required this.familySize,
    Recipe? editing,
    RecipeDraft? draft,
  }) : _meals = mealRepository,
       recipeId = editing?.id ?? OwnRecipeIds.newRecipeId(),
       isEditing = editing != null,
       isCutShort = draft != null && RecipeForm.cutsShort(draft),
       candidateImageUrls = draft?.candidateImageUrls ?? const [],
       _form = switch ((editing, draft)) {
         (final recipe?, _) => RecipeForm.fromRecipe(recipe),
         (_, final draft?) => RecipeForm.fromDraft(draft),
         _ => const RecipeForm(),
       },
       _isDirty = draft != null {
    _derived = _form.derivedAllergens;
    _keptAtStart = _keptPaths(_form);
  }

  final OwnRecipeRepository _ownRecipes;
  final OwnRecipePhotoStore _photoStore;
  final RecipePhotoPicker _photoPicker;
  final RecipePhotoIntake _photoIntake;
  final RecipePhotoSource _photoSource;
  final MealRepository _meals;
  final String householdId;
  final String viewerUid;
  final int familySize;

  /// Made once per builder, so a retried Save is the same recipe.
  final String recipeId;
  final bool isEditing;
  final bool isCutShort;

  /// For whoever fetches a link's pictures: each comes in by [addPhotoBytes].
  final List<String> candidateImageUrls;

  RecipeForm _form;
  late Set<Allergen> _derived;
  late final Set<String> _keptAtStart;
  final _storedThisSession = <String>{};
  bool _isDirty;
  bool _isAddingPhotos = false;
  bool _isSaving = false;
  bool _hasTriedToSave = false;
  bool _missedMealLines = false;
  bool _isDisposed = false;
  Future<void>? _arriving;

  RecipeForm get form => _form;
  Set<Allergen> get derivedAllergens => _derived;
  bool get isDirty => _isDirty;
  bool get isAddingPhotos => _isAddingPhotos;
  bool get isSaving => _isSaving;

  List<RecipeFormProblem> get shownProblems =>
      _hasTriedToSave ? _form.problems : const [];

  bool get missedMealLines => _missedMealLines;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void update(RecipeForm Function(RecipeForm form) change) {
    _form = change(_form);
    _derived = _form.derivedAllergens;
    _isDirty = true;
    notifyListeners();
  }

  Future<void> addPhotos(RecipePhotoOrigin origin) async {
    if (_isAddingPhotos || _isSaving || !_form.canAddPhoto) return;
    _isAddingPhotos = true;
    notifyListeners();
    await runAction(() async {
      final picked = await _photoPicker.pick(origin, limit: _form.photosLeft);
      AppFailure? refused;
      for (final original in picked) {
        try {
          await addPhotoBytes(original);
        } on AppFailure catch (failure) {
          refused = failure;
        }
      }
      if (refused case final failure?) throw failure;
    });
    _isAddingPhotos = false;
    notifyListeners();
  }

  Future<void> addPhotoBytes(
    Uint8List original, {
    String? credit,
    String? sourceUrl,
  }) async {
    addPhotoCuts(
      await _photoIntake.cut(original),
      credit: credit,
      sourceUrl: sourceUrl,
    );
  }

  String addPhotoCuts(
    RecipePhotoCuts cuts, {
    String? credit,
    String? sourceUrl,
  }) {
    final photoId = OwnRecipeIds.newPhotoId();
    update(
      (form) => form.withPhoto(
        NewRecipeFormPhoto(
          photoId: photoId,
          cuts: cuts,
          credit: credit,
          sourceUrl: sourceUrl,
        ),
      ),
    );
    return photoId;
  }

  void holdSaveFor(Future<void> arrival) => _arriving = arrival;

  Future<bool> save() async {
    if (_isSaving) return false;
    _hasTriedToSave = true;
    if (_form.problems.isNotEmpty) {
      notifyListeners();
      return false;
    }
    _isSaving = true;
    _missedMealLines = false;
    clearFailureQuietly();
    notifyListeners();
    var isDone = false;
    try {
      await _arriving;
      final save = _form.toSave();
      await _uploadAndSave(save);
      await _bringPlannedMealUpToDate(save);
      await _forgetDroppedPhotos();
      _isDirty = false;
      isDone = true;
    } on AppFailure catch (failure) {
      recordFailure(failure);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return isDone;
  }

  Future<void> _uploadAndSave(OwnRecipeSave save) async {
    try {
      await _uploadNewPhotos();
      await _ownRecipes.save(
        householdId: householdId,
        recipeId: recipeId,
        recipe: save,
      );
    } on UnavailableFailure {
      // The call may have landed with no answer reaching the phone, so its
      // photos stay: Storage is create-only, and a retry skips them.
      rethrow;
    } on AppFailure {
      await _removeWhatThisSessionStored();
      rethrow;
    }
  }

  Future<void> _uploadNewPhotos() async {
    for (final photo in _form.photos.whereType<NewRecipeFormPhoto>()) {
      await _upload(
        OwnRecipePhotoPaths.card(householdId, recipeId, photo.photoId),
        photo.cuts.card.bytes,
      );
      await _upload(
        OwnRecipePhotoPaths.hero(householdId, recipeId, photo.photoId),
        photo.cuts.hero.bytes,
      );
    }
  }

  Future<void> _upload(String path, Uint8List bytes) async {
    if (_storedThisSession.contains(path)) return;
    await _photoStore.upload(path: path, uploaderUid: viewerUid, bytes: bytes);
    _storedThisSession.add(path);
  }

  Future<void> _removeWhatThisSessionStored() async {
    for (final path in [..._storedThisSession]) {
      final error = await bestEffort(
        'remove orphaned recipe photo',
        code: 'orphan-photo',
        run: () => _photoStore.remove(path),
      );
      if (error == null) _storedThisSession.remove(path);
    }
  }

  Future<void> _bringPlannedMealUpToDate(OwnRecipeSave save) async {
    if (!isEditing) return;
    final error = await bestEffort(
      'rewrite planned recipe lines',
      code: 'planned-lines',
      run: () => _meals.rewriteOwnRecipeMealLines(
        householdId: householdId,
        recipeId: recipeId,
        ingredients: mealLinesOf(
          save.ingredients,
          RecipeScale(
            people: familySize > 0 ? familySize : save.servings,
            servings: save.servings,
          ),
        ),
      ),
    );
    _missedMealLines = error != null;
  }

  Future<void> _forgetDroppedPhotos() async {
    final dropped = _keptAtStart.difference(_keptPaths(_form));
    if (dropped.isNotEmpty) await _photoSource.forget(dropped);
  }

  static Set<String> _keptPaths(RecipeForm form) => {
    for (final photo in form.photos.whereType<KeptRecipeFormPhoto>()) ...[
      photo.stored.card,
      photo.stored.hero,
    ],
  };
}
