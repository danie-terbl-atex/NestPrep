import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/recipe_document_reader.dart';
import '../data/recipe_pdf.dart';
import '../data/recipe_pdf_document.dart';
import '../data/shared_pdf_inbox.dart';
import '../model/recipe_document.dart';
import '../model/recipe_draft.dart';
import 'own_recipe_importer.dart';
import 'recipe_photo_intake.dart';

enum RecipeDocumentStep {
  start,
  opening,
  scanning,
  nothingFound,
  choosing,
  drafting,
  importing,
  stopped,
}

/// A PDF on its way to the household's recipes (recipes ADR-0009). One read
/// finds the recipes; the member picks; each picked one is read on its own
/// pages and saved as it is. One recipe opens the builder instead, like a link
/// or a snap. The PDF is held only until nothing more needs reading from it.
final class RecipeDocumentController extends ChangeNotifier {
  RecipeDocumentController({
    required this._picker,
    required this._inbox,
    required this._rasterizer,
    required this._reader,
    required this._importer,
    required this._photoIntake,
    required this.householdId,
    this._work,
  });

  static const maxPerImport = 12;
  static const _together = 2;

  /// The photo choices a draft may send: the server's `MAX_PHOTO_CHOICES`.
  static const _photoChoices = 8;

  final RecipePdfPicker _picker;
  final SharedPdfInbox _inbox;
  final PdfRasterizer _rasterizer;
  final RecipeDocumentReader _reader;
  final OwnRecipeImporter _importer;
  final RecipePhotoIntake _photoIntake;
  final PictureWork? _work;
  final String householdId;

  RecipeDocumentStep _step = RecipeDocumentStep.start;
  AppFailure? _failure;
  String _documentName = '';
  RecipePdfDocument? _document;
  PickedPdf? _offered;
  int _pagesDrawn = 0;
  int _pageCount = 0;
  final _thumbnails = <int, Uint8List>{};
  List<FoundDocumentRecipe> _found = const [];
  final _chosen = <int>{};
  int? _callsLeft;
  List<DocumentImportRow> _rows = const [];
  RecipeDraft? _builderDraft;
  bool _isDisposed = false;

  RecipeDocumentStep get step => _step;
  AppFailure? get failure => _failure;
  String get documentName => _documentName;
  int get pagesDrawn => _pagesDrawn;
  int get pageCount => _pageCount;
  List<FoundDocumentRecipe> get found => _found;
  int? get callsLeft => _callsLeft;
  List<DocumentImportRow> get rows => _rows;
  bool get holdsDocument => _document != null || _offered != null;

  /// The name of a PDF shared from another app, waiting for the member to
  /// say read it.
  String? get offeredName => _offered?.name;

  /// Set once, when a PDF with one recipe is ready for the builder.
  RecipeDraft? get builderDraft => _builderDraft;

  Uint8List? thumbnailOf(FoundDocumentRecipe recipe) =>
      _thumbnails[recipe.firstPage];

  bool isChosen(int at) => _chosen.contains(at);
  int get chosenCount => _chosen.length;

  int get mostChosen =>
      min(maxPerImport, min(_found.length, _callsLeft ?? maxPerImport));

  bool get isImporting =>
      _step == RecipeDocumentStep.importing && _rows.any((row) => !row.isDone);

  bool get isBusy => switch (_step) {
    RecipeDocumentStep.opening ||
    RecipeDocumentStep.scanning ||
    RecipeDocumentStep.drafting => true,
    RecipeDocumentStep.importing => isImporting,
    _ => false,
  };

  int get savedCount =>
      _rows.where((row) => row.state == DocumentImportState.saved).length;

  void toggle(int at) {
    if (_step != RecipeDocumentStep.choosing) return;
    if (!_chosen.remove(at) && _chosen.length < mostChosen) _chosen.add(at);
    _notify();
  }

  Future<void> pick() async {
    if (isBusy) return;
    final PickedPdf? pdf;
    try {
      pdf = await _picker.pick();
    } on AppFailure catch (failure) {
      return _stop(failure);
    }
    if (pdf == null) return;
    await _read(pdf);
  }

  Future<void> receive(String token) async {
    if (isBusy) return;
    final PickedPdf? pdf;
    try {
      pdf = await _inbox.take(token);
    } on AppFailure catch (failure) {
      return _stop(failure);
    }
    if (_isDisposed) return;
    if (pdf == null) {
      return _stop(const OwnRecipeFailure(OwnRecipeProblem.documentShareGone));
    }
    _offered = pdf;
    _notify();
  }

  Future<void> readOffered() async {
    final pdf = _offered;
    if (pdf == null || isBusy) return;
    await _read(pdf);
  }

  Future<void> importChosen() async {
    if (_step != RecipeDocumentStep.choosing || _chosen.isEmpty) return;
    _rows = [
      for (final at in _chosen.toList()..sort())
        DocumentImportRow(recipe: _found[at]),
    ];
    _moveTo(RecipeDocumentStep.importing);
    await _run([for (var at = 0; at < _rows.length; at++) at]);
  }

  Future<void> retry(int at) async {
    if (at >= _rows.length || _rows[at].state != DocumentImportState.failed) {
      return;
    }
    if (_document == null) return;
    await _run([at]);
  }

  Future<void> _read(PickedPdf pdf) async {
    _forget();
    _documentName = pdf.name;
    _moveTo(RecipeDocumentStep.opening);
    try {
      final work = _work;
      final document = work == null
          ? await RecipePdfDocument.open(_rasterizer, pdf.bytes)
          : await RecipePdfDocument.open(_rasterizer, pdf.bytes, work: work);
      _document = document;
      _pageCount = document.pageCount;
      final pages = <DocumentScanPage>[];
      await for (final page in document.scanPages()) {
        if (_isDisposed) return;
        pages.add(page);
        _thumbnails[page.number] = page.jpeg;
        _pagesDrawn = pages.length;
        _notify();
      }
      _moveTo(RecipeDocumentStep.scanning);
      final scan = await _reader.scan(
        householdId: householdId,
        documentName: pdf.name,
        pages: pages,
      );
      _callsLeft = scan.callsLeft;
      _found = scan.recipes;
      if (_found.isEmpty) {
        _letGo();
        return _moveTo(RecipeDocumentStep.nothingFound);
      }
      if (_found.length == 1) return await _draftForBuilder(_found.single);
      _chosen.addAll([for (var at = 0; at < mostChosen; at++) at]);
      _moveTo(RecipeDocumentStep.choosing);
    } on AppFailure catch (failure) {
      _letGo();
      _stop(failure);
    }
  }

  Future<void> _draftForBuilder(FoundDocumentRecipe recipe) async {
    _moveTo(RecipeDocumentStep.drafting);
    final draft = await _drafted(recipe);
    _letGo();
    if (draft == null) return _moveTo(RecipeDocumentStep.nothingFound);
    _builderDraft = draft;
    _notify();
  }

  Future<void> _run(List<int> indexes) async {
    final waiting = [...indexes];
    Future<void> worker() async {
      while (waiting.isNotEmpty && !_isDisposed) {
        await _import(waiting.removeAt(0));
      }
    }

    await Future.wait([for (var at = 0; at < _together; at++) worker()]);
    if (_rows.every(
      (row) => row.isDone && row.state != DocumentImportState.failed,
    )) {
      _letGo();
    }
    _notify();
  }

  Future<void> _import(int at) async {
    _setRow(at, DocumentImportState.reading);
    try {
      final draft = await _drafted(_rows[at].recipe);
      if (_isDisposed) return;
      if (draft == null) return _setRow(at, DocumentImportState.notARecipe);
      final isSaved = await _importer.save(draft);
      _setRow(
        at,
        isSaved ? DocumentImportState.saved : DocumentImportState.unfinished,
        draft: isSaved ? null : draft,
      );
    } on AppFailure catch (failure) {
      _setRow(at, DocumentImportState.failed, failure: failure);
    }
  }

  Future<RecipeDraft?> _drafted(FoundDocumentRecipe recipe) async {
    final document = _document;
    if (document == null) {
      throw const OwnRecipeFailure(OwnRecipeProblem.documentUnreadable);
    }
    final pages = await document.readPages(
      recipe.readPages,
      wholes: recipe.pages.take(_photoChoices).toSet(),
    );
    final reading = await _reader.draft(
      householdId: householdId,
      documentName: _documentName,
      recipeName: recipe.name,
      pages: pages,
    );
    _callsLeft = reading.callsLeft;
    final draft = reading.draft;
    final photo = reading.photo;
    if (draft == null) return null;
    if (photo == null || photo.page < 1 || photo.page > document.pageCount) {
      return draft;
    }
    try {
      return draft.withPhotos([
        await _photoIntake.cut(await document.photo(photo)),
      ]);
    } on AppFailure {
      return draft;
    }
  }

  void _setRow(
    int at,
    DocumentImportState state, {
    AppFailure? failure,
    RecipeDraft? draft,
  }) {
    _rows = [
      for (var index = 0; index < _rows.length; index++)
        index == at
            ? _rows[index].moveTo(state, failure: failure, draft: draft)
            : _rows[index],
    ];
    _notify();
  }

  void _letGo() {
    _document = null;
    _offered = null;
  }

  void _forget() {
    _letGo();
    _failure = null;
    _pagesDrawn = 0;
    _pageCount = 0;
    _thumbnails.clear();
    _found = const [];
    _chosen.clear();
    _rows = const [];
    _builderDraft = null;
  }

  void _stop(AppFailure failure) =>
      _moveTo(RecipeDocumentStep.stopped, failure: failure);

  void _moveTo(RecipeDocumentStep step, {AppFailure? failure}) {
    _step = step;
    _failure = failure;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _letGo();
    super.dispose();
  }
}
