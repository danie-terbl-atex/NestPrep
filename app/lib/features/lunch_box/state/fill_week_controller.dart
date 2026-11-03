import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../recipes/data/recipe_repository.dart';
import '../data/lunch_repository.dart';
import '../data/lunch_starter_box_repository.dart';
import '../model/fill_week_box.dart';
import '../model/fill_week_preview.dart';
import '../model/lunch_auto_fill.dart';
import '../model/lunch_board.dart';
import '../model/lunch_fill_choice.dart';
import '../model/lunch_starter_box.dart';
import '../model/lunch_variety.dart';
import 'fill_week_step.dart';
import 'lunch_library_items.dart';
import 'lunch_variety_choice.dart';
import 'ready_made_box_offer.dart';
import 'starter_box_items.dart';
import 'week_picks_writer.dart';

export 'fill_week_step.dart';

/// *Fill the week* for one child (lunch-box ADR-0020): the boxes the parent
/// chooses — their own go-to boxes and NestPrep's ready-made ones — then the
/// whole week as `LunchAutoFill` would fill it, then the write. It follows
/// the lunch board, so every check is against the child, their rules and
/// the library the phone holds now; nothing is written before [fill].
final class FillWeekController extends ChangeNotifier {
  FillWeekController({
    required LunchStarterBoxRepository starterBoxes,
    required RecipeRepository recipes,
    required LunchRepository lunchRepository,
    required this.variety,
    required this.householdId,
    required this.memberId,
    required this.childId,
  }) : _items = StarterBoxItems(
         library: LunchLibraryItems(
           lunchRepository: lunchRepository,
           householdId: householdId,
         ),
       ),
       _writer = WeekPicksWriter(
         lunchRepository: lunchRepository,
         householdId: householdId,
       ) {
    readyMade = ReadyMadeBoxOffer(
      boxes: starterBoxes,
      recipes: recipes,
      onChange: _changed,
    );
    variety.addListener(_changed);
    unawaited(readyMade.load());
  }

  /// Which compartments keep the same all week — the review's chips, shared
  /// with *Plan my week* (lunch-box ADR-0028).
  final LunchVarietyChoice variety;
  final String householdId;
  final String memberId;
  final String childId;
  final StarterBoxItems _items;
  final WeekPicksWriter _writer;
  late final ReadyMadeBoxOffer readyMade;

  AsyncState<LunchBoard> _board = const AsyncLoading();
  FillWeekStep _step = FillWeekStep.boxes;
  var _chosen = <String>[];
  bool _isSaving = false;
  AppFailure? _failure;
  WrittenPicks? _written;
  var _isDisposed = false;
  _Derived? _derived;

  AsyncState<LunchBoard> get board => _board;
  FillWeekStep get step => _step;
  bool get isSaving => _isSaving;

  /// What went wrong writing the week, for a banner.
  AppFailure? get failure => _failure;

  /// What the write put in, once it has.
  WrittenPicks? get written => _written;

  /// The child on the board, or null while it loads or when the board has
  /// no such child.
  LunchChildWeek? get childWeek => _latestBoard?.childWeek(childId);

  /// The child's go-to boxes, in rotation order.
  List<FillWeekBox> get goToBoxes => _derive()?.goTo ?? const [];

  /// NestPrep's ready-made boxes, as this child would have them — or why
  /// they could not be read.
  AsyncState<List<FillWeekBox>> get readyMadeBoxes {
    final derived = _derive();
    return switch (readyMade.state) {
      AsyncFailure(:final failure) => AsyncFailure(failure),
      AsyncData() when derived != null => AsyncData(derived.readyMade),
      _ => const AsyncLoading(),
    };
  }

  /// The boxes chosen, in the order they were — the order they take turns.
  List<FillWeekBox> get chosenBoxes => _derive()?.chosen ?? const [];

  /// Where [box] is in the turns, from 1, or null when it is not chosen.
  int? turnOf(FillWeekBox box) {
    final index = chosenBoxes.indexWhere((each) => each.id == box.id);
    return index < 0 ? null : index + 1;
  }

  /// The week the fill would leave, from the board as it is now.
  FillWeekPreview? get preview => _derive()?.preview;

  void followBoard(AsyncState<LunchBoard> board) {
    if (identical(board, _board)) return;
    _board = board;
    _changed();
  }

  void toggle(FillWeekBox box) {
    if (!box.canBeChosen || _isSaving) return;
    _chosen = _chosen.contains(box.id)
        ? [..._chosen.where((id) => id != box.id)]
        : [..._chosen, box.id];
    _changed();
  }

  /// Boxes → the week, with the boxes chosen.
  void review() {
    if (chosenBoxes.isEmpty) return;
    _step = FillWeekStep.review;
    _changed();
  }

  /// *Skip — fill it all for me*: no boxes, and on to the week.
  void skip() {
    _chosen = [];
    _step = FillWeekStep.review;
    _changed();
  }

  void back() {
    if (_isSaving) return;
    _step = _step.previous;
    _failure = null;
    _changed();
  }

  void dismissFailure() {
    _failure = null;
    _changed();
  }

  /// Writes the week as the board has it now: ready-made picks made library
  /// items first, then the child's picks one school day per write, never
  /// over what was packed meanwhile, never anything no longer safe
  /// (lunch-box ADR-0020 §5).
  Future<void> fill() async {
    final board = _latestBoard;
    final derived = _derive();
    if (board == null || derived == null || _isSaving) return;
    final result = derived.preview.result;
    if (result.isEmpty) return;
    _isSaving = true;
    _failure = null;
    _changed();
    try {
      final picks = await _items.ensure(
        result.picks,
        candidates: {for (final box in derived.chosen) ...box.candidates},
        board: board,
      );
      _written = await _writer.write(
        board: _latestBoard ?? board,
        week: board.week,
        picksByChild: {childId: picks},
      );
      _step = FillWeekStep.done;
    } on AppFailure catch (failure) {
      _failure = failure;
    }
    _isSaving = false;
    _changed();
  }

  LunchBoard? get _latestBoard => switch (_board) {
    AsyncData(:final value) => value,
    _ => null,
  };

  /// Everything worked out from the board, the offer and the choice, once
  /// per change of any of them (`FE-12`).
  _Derived? _derive() {
    final cached = _derived;
    if (cached != null) return cached;
    final board = _latestBoard;
    final child = board?.childWeek(childId);
    if (board == null || child == null) return null;
    return _derived = _Derived.of(
      board: board,
      child: child,
      offer: switch (readyMade.state) {
        AsyncData(:final value) => value,
        _ => null,
      },
      chosenIds: _chosen,
      memberId: memberId,
      variety: variety.variety,
    );
  }

  void _changed() {
    _derived = null;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    variety.removeListener(_changed);
    readyMade.close();
    super.dispose();
  }
}

/// The boxes on offer for the child, those chosen, and the week they make.
final class _Derived {
  _Derived({
    required this.goTo,
    required this.readyMade,
    required this.chosen,
    required this.preview,
  });

  factory _Derived.of({
    required LunchBoard board,
    required LunchChildWeek child,
    required StarterBoxOffer? offer,
    required List<String> chosenIds,
    required String memberId,
    required LunchVariety variety,
  }) {
    final rules = child.child.foodRules;
    final goTo = [
      for (final favourite in child.favourites)
        FillWeekBox.goTo(favourite, rules: rules, library: board.libraryById),
    ];
    final readyMade = [
      for (final box in offer?.boxes ?? const <LunchStarterBox>[])
        FillWeekBox.readyMade(
          box,
          recipes: offer?.recipes ?? const {},
          rules: rules,
          library: board.libraryById,
          addedBy: memberId,
        ),
    ];
    final byId = {
      for (final box in [...goTo, ...readyMade]) box.id: box,
    };
    final chosen = [
      for (final id in chosenIds)
        if (byId[id] case final box? when box.canBeChosen) box,
    ];
    final result = LunchAutoFill.fill(
      plan: child.plan,
      week: board.week,
      favourites: child.favourites,
      library: board.library,
      rules: rules,
      taste: child.taste,
      choice: LunchFillChoice(today: board.today, boxes: chosen),
      variety: variety,
    );
    return _Derived(
      goTo: goTo,
      readyMade: readyMade,
      chosen: chosen,
      preview: FillWeekPreview.of(child, result),
    );
  }

  final List<FillWeekBox> goTo;
  final List<FillWeekBox> readyMade;
  final List<FillWeekBox> chosen;
  final FillWeekPreview preview;
}
