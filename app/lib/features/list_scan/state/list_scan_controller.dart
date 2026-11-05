import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../recipes/data/recipe_groceries.dart';
import '../../recipes/model/recipe_shop_line.dart';
import '../data/list_photo_picker.dart';
import '../data/list_scan_reader.dart';
import '../model/list_photo.dart';
import '../model/list_scan_line.dart';

enum ListScanStep { choosing, reading, review, adding, done }

/// Snap a shopping list (list-scan ADR-0001): picks a photo, has it read,
/// holds the review, and adds **only** the lines the member kept — straight
/// onto the list as items they typed, or through *Add to grocer*'s sheet,
/// matched at the shop, which the screen opens with [shopLines].
///
/// The review is this screen's own state; the lines exist nowhere else until
/// they are on the list (`FE-07`).
final class ListScanController extends ChangeNotifier {
  ListScanController({
    required ListScanReader listScanReader,
    required ListPhotoPicker listPhotoPicker,
    required this._groceries,
    required this.householdId,
  }) : _reader = listScanReader,
       _picker = listPhotoPicker;

  final ListScanReader _reader;
  final ListPhotoPicker _picker;
  final RecipeGroceries _groceries;
  final String householdId;

  ListScanStep _step = ListScanStep.choosing;
  AppFailure? _failure;
  ListPhoto? _photo;
  List<ListScanLine> _lines = const [];
  int? _callsLeft;
  int _added = 0;

  ListScanStep get step => _step;
  AppFailure? get failure => _failure;
  List<ListScanLine> get lines => _lines;
  int? get callsLeft => _callsLeft;

  int get added => _added;

  int get includedCount => _lines.where((line) => line.isIncluded).length;

  /// Twig welcomes only a fresh start (design-system ADR-0012).
  bool get isAiWelcome => _step == ListScanStep.choosing && _failure == null;

  bool get canRetry => _photo != null && _step == ListScanStep.choosing;

  List<RecipeShopLine> get shopLines => [
    for (final line in _lines)
      if (line.isIncluded) _shopLineOf(line),
  ];

  Future<void> pick(ListPhotoSource source) async {
    if (_step == ListScanStep.reading || _step == ListScanStep.adding) return;
    final ListPhoto? photo;
    try {
      photo = await _picker.pick(source);
    } on AppFailure catch (failure) {
      _moveTo(ListScanStep.choosing, failure: failure);
      return;
    }
    if (photo == null) return;
    await _read(photo);
  }

  Future<void> retry() async {
    final photo = _photo;
    if (photo != null) await _read(photo);
  }

  void toggle(int key) => _update(key, (line) => line.toggled());

  void leaveOff(int key) =>
      _update(key, (line) => line.isIncluded ? line.toggled() : line);

  /// The member's own words for a line. Changing it keeps it: nobody fixes a
  /// line they mean to leave off.
  void change(int key, {required String name, required String? quantity}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final amount = quantity?.trim();
    _update(
      key,
      (line) => line.changed(
        name: trimmed,
        quantity: amount == null || amount.isEmpty ? null : amount,
      ),
    );
  }

  /// Adds the kept lines by name, each once: a line already waiting on the
  /// list is not added again (recipes ADR-0005's writer).
  Future<void> addToList() async {
    if (_step != ListScanStep.review || includedCount == 0) return;
    _moveTo(ListScanStep.adding);
    try {
      final added = await _groceries.add(shopLines);
      _finish(
        added.unmatched + added.matched.where((entry) => entry.isNew).length,
      );
    } on AppFailure catch (failure) {
      _moveTo(ListScanStep.review, failure: failure);
    }
  }

  /// *Add to grocer*'s sheet put [added] lines on the list; null when it was
  /// closed before anything was added, and the review stays.
  void shopped(int? added) {
    if (added == null || _step != ListScanStep.review) return;
    _finish(added);
  }

  void startOver() {
    _photo = null;
    _lines = const [];
    _added = 0;
    _moveTo(ListScanStep.choosing);
  }

  void dismissFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  Future<void> _read(ListPhoto photo) async {
    _photo = photo;
    _moveTo(ListScanStep.reading);
    try {
      final reading = await _reader.read(
        householdId: householdId,
        photo: photo,
      );
      _callsLeft = reading.callsLeft;
      _lines = reading.lines;
      _moveTo(ListScanStep.review);
    } on AppFailure catch (failure) {
      _moveTo(ListScanStep.choosing, failure: failure);
    }
  }

  void _finish(int added) {
    _added = added;
    _photo = null;
    _lines = const [];
    _moveTo(ListScanStep.done);
  }

  static RecipeShopLine _shopLineOf(ListScanLine line) =>
      RecipeShopLine(index: line.key, name: line.name, quantity: line.quantity);

  void _update(int key, ListScanLine Function(ListScanLine line) edit) {
    if (_step != ListScanStep.review) return;
    _lines = [for (final line in _lines) line.key == key ? edit(line) : line];
    notifyListeners();
  }

  void _moveTo(ListScanStep step, {AppFailure? failure}) {
    _step = step;
    _failure = failure;
    notifyListeners();
  }
}
