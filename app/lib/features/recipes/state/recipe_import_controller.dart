import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../list_scan/data/list_photo_picker.dart';
import '../../list_scan/model/list_photo.dart';
import '../data/page_link.dart';
import '../data/recipe_drafter.dart';
import '../data/recipe_page_reader.dart';
import '../model/recipe_draft.dart';
import '../model/recipe_draft_reading.dart';
import '../model/recipe_form.dart';
import '../model/recipe_import_way.dart';
import '../model/recipe_origin.dart';
import '../model/recipe_page.dart';

enum RecipeImportStep { start, readingPage, askingAi, stopped, done }

final class RecipeImportController extends ChangeNotifier {
  RecipeImportController({
    required RecipePageReader pageReader,
    required this._drafter,
    required ListPhotoPicker photoPicker,
    required this.householdId,
    required this._way,
  }) : _reader = pageReader,
       _picker = photoPicker;

  final RecipePageReader _reader;
  final RecipeDrafter _drafter;
  final ListPhotoPicker _picker;
  final String householdId;

  RecipeImportWay _way;
  RecipeImportStep _step = RecipeImportStep.start;
  AppFailure? _failure;
  String? _link;
  RecipePage? _page;
  ListPhoto? _photo;
  RecipeDraft? _draft;
  int? _callsLeft;
  bool _isDisposed = false;

  RecipeImportWay get way => _way;
  RecipeImportStep get step => _step;
  AppFailure? get failure => _failure;
  RecipeDraft? get draft => _draft;
  int? get callsLeft => _callsLeft;

  String? get carriedLink => _link;

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
    _photo = null;
    if (link == null) {
      return _stop(
        const RecipeImportFailure(RecipeImportProblem.linkNotPublic),
      );
    }
    await _readPage(link);
  }

  Future<void> pick(ListPhotoSource source) async {
    if (_isBusy) return;
    final ListPhoto? photo;
    try {
      photo = await _picker.pick(source);
    } on AppFailure catch (failure) {
      return _moveTo(RecipeImportStep.start, failure: failure);
    }
    if (photo == null) return;
    _photo = photo;
    await _askAboutPhoto(photo);
  }

  Future<void> retry() async {
    if (!canRetry) return;
    // The page is kept: only the model is asked again, never the site.
    if (_page case final page?) return _askAboutPage(page);
    if (_photo case final photo?) return _askAboutPhoto(photo);
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

  Future<void> _askAboutPhoto(ListPhoto photo) =>
      _ask(() => _drafter.fromPhoto(householdId: householdId, photo: photo));

  Future<void> _ask(Future<RecipeDraftReading> Function() asked) async {
    _moveTo(RecipeImportStep.askingAi);
    try {
      final reading = await asked();
      _callsLeft = reading.callsLeft;
      final draft = reading.draft;
      if (draft == null) {
        return _stop(const RecipeImportFailure(RecipeImportProblem.noRecipe));
      }
      _draft = _withCarriedLink(draft);
      _moveTo(RecipeImportStep.done);
    } on AppFailure catch (failure) {
      _stop(failure);
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
