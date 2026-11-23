import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../list_scan/data/list_photo_picker.dart';
import '../data/page_link.dart';
import '../data/recipe_drafter.dart';
import '../data/recipe_page_reader.dart';
import '../data/recipe_snap_picker.dart';
import '../data/recipe_snap_pictures.dart';
import '../model/recipe_draft.dart';
import '../model/recipe_draft_reading.dart';
import '../model/recipe_form.dart';
import '../model/recipe_import_way.dart';
import '../model/recipe_origin.dart';
import '../model/recipe_page.dart';
import '../model/recipe_snap.dart';
import 'recipe_photo_intake.dart';

enum RecipeImportStep { start, readingPage, askingAi, stopped, done }

final class RecipeImportController extends ChangeNotifier {
  RecipeImportController({
    required RecipePageReader pageReader,
    required this._drafter,
    required RecipeSnapPicker snapPicker,
    required this.householdId,
    required this._way,
    this._photoIntake = const RecipePhotoIntake(),
  }) : _reader = pageReader,
       _picker = snapPicker;

  final RecipePageReader _reader;
  final RecipeDrafter _drafter;
  final RecipeSnapPicker _picker;
  final RecipePhotoIntake _photoIntake;
  final String householdId;

  RecipeImportWay _way;
  RecipeImportStep _step = RecipeImportStep.start;
  AppFailure? _failure;
  String? _link;
  RecipePage? _page;
  final _snaps = <RecipeSnap>[];
  bool _isAdding = false;
  RecipeDraft? _draft;
  int? _callsLeft;
  bool _isDisposed = false;

  RecipeImportWay get way => _way;
  RecipeImportStep get step => _step;
  AppFailure? get failure => _failure;
  RecipeDraft? get draft => _draft;
  int? get callsLeft => _callsLeft;

  String? get carriedLink => _link;

  List<RecipeSnap> get snaps => List.unmodifiable(_snaps);
  bool get isAdding => _isAdding;

  bool get canAddPhoto => _photoRoom > 0 && _partRoom > 0;

  int get _photoRoom => RecipeSnap.maxPhotos - _snaps.length;

  int get _partRoom =>
      RecipeSnap.maxParts -
      _snaps.fold(0, (total, snap) => total + snap.parts.length);

  bool get isAiWelcome => _step == RecipeImportStep.start && _failure == null;

  bool get _isBusy =>
      _step == RecipeImportStep.readingPage ||
      _step == RecipeImportStep.askingAi;

  /// Never for a site that refused: asking again is not ours to do.
  bool get canRetry => switch (_failure) {
    AiFailure(problem: AiProblem.aiUnavailable || AiProblem.aiUnreadable) ||
    UnavailableFailure() ||
    RecipeImportFailure(problem: RecipeImportProblem.pageUnreachable) => true,
    _ => false,
  };

  /// A snapped photo goes through the same switch and the same month's reads.
  bool get canSnapInstead => switch (_failure) {
    AiFailure(problem: AiProblem.aiSwitchedOff || AiProblem.aiLimitReached) ||
    PremiumRequiredFailure() => false,
    _ => true,
  };

  RecipeDraft get typedDraft {
    final link = _link;
    return RecipeDraft(
      servings: RecipeForm.defaultServings,
      sourceUrl: link,
      sourceName: link == null ? null : siteNameOf(link),
    );
  }

  Future<void> readLink(String raw) async {
    if (_isBusy) return;
    final link = pageLink(raw);
    _link = link;
    _page = null;
    _snaps.clear();
    if (link == null) {
      return _stop(
        const RecipeImportFailure(RecipeImportProblem.linkNotPublic),
      );
    }
    await _readPage(link);
  }

  Future<void> addPhotos(ListPhotoSource source) async {
    if (_isBusy || _isAdding || !canAddPhoto) return;
    _isAdding = true;
    _moveTo(RecipeImportStep.start);
    AppFailure? problem;
    try {
      final pick = await _picker.pick(
        source,
        photoRoom: _photoRoom,
        partRoom: _partRoom,
      );
      _snaps.addAll(pick.snaps);
      problem = pick.problem;
    } on AppFailure catch (failure) {
      problem = failure;
    } finally {
      _isAdding = false;
      _moveTo(RecipeImportStep.start, failure: problem);
    }
  }

  void removePhoto(RecipeSnap snap) {
    if (_isBusy || !_snaps.remove(snap)) return;
    _moveTo(RecipeImportStep.start);
  }

  Future<void> readPhotos() async {
    if (_isBusy || _isAdding || _snaps.isEmpty) return;
    await _askAboutPhotos();
  }

  Future<void> retry() async {
    if (!canRetry) return;
    // The page is kept: only the model is asked again, never the site.
    if (_page case final page?) return _askAboutPage(page);
    if (_snaps.isNotEmpty) return _askAboutPhotos();
    if (_link case final link?) return _readPage(link);
  }

  void useScreenshot() {
    _way = RecipeImportWay.snap;
    _page = null;
    _moveTo(RecipeImportStep.start);
  }

  Future<void> _readPage(String link) async {
    _moveTo(RecipeImportStep.readingPage);
    final RecipePage page;
    try {
      page = await _reader.read(link);
    } on AppFailure catch (failure) {
      if (failure case RecipeImportFailure(
        problem: RecipeImportProblem.linkNotPublic,
      )) {
        _link = null;
      }
      return _stop(failure);
    }
    _page = page;
    await _askAboutPage(page);
  }

  Future<void> _askAboutPage(RecipePage page) =>
      _ask(() => _drafter.fromPage(householdId: householdId, page: page));

  Future<void> _askAboutPhotos() {
    final photos = snaps;
    return _ask(
      () => _drafter.fromPhotos(householdId: householdId, photos: photos),
      photos: photos,
    );
  }

  Future<void> _ask(
    Future<RecipeDraftReading> Function() asked, {
    List<RecipeSnap> photos = const [],
  }) async {
    _moveTo(RecipeImportStep.askingAi);
    try {
      final reading = await asked();
      _callsLeft = reading.callsLeft;
      final draft = reading.draft;
      if (draft == null) {
        return _stop(const RecipeImportFailure(RecipeImportProblem.noRecipe));
      }
      _draft = _withCarriedLink(await _withDish(draft, reading.dish, photos));
      _moveTo(RecipeImportStep.done);
    } on AppFailure catch (failure) {
      _stop(failure);
    }
  }

  /// A recipe the dish's photo could not be cut for is still the recipe.
  Future<RecipeDraft> _withDish(
    RecipeDraft draft,
    RecipeSnapDish? dish,
    List<RecipeSnap> photos,
  ) async {
    if (dish == null || dish.photo < 1 || dish.photo > photos.length) {
      return draft;
    }
    final snap = photos[dish.photo - 1];
    final cut = await Isolate.run(
      () => RecipeSnapPictures.dishPhoto(snap, dish),
    );
    if (cut == null) return draft;
    try {
      return draft.withPhotos([await _photoIntake.cut(cut)]);
    } on AppFailure {
      return draft;
    }
  }

  RecipeDraft _withCarriedLink(RecipeDraft draft) {
    final link = _link;
    if (link == null || draft.origin != RecipeOrigin.photo) return draft;
    return draft.withSource(url: link, name: siteNameOf(link));
  }

  void _stop(AppFailure failure) =>
      _moveTo(RecipeImportStep.stopped, failure: failure);

  void _moveTo(RecipeImportStep step, {AppFailure? failure}) {
    _step = step;
    _failure = failure;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
