import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/lunch_pantry_repository.dart';
import '../data/lunch_repository.dart';
import '../model/lunch_board.dart';
import '../model/lunch_box.dart';
import '../model/lunch_item_draft.dart';
import '../model/lunch_pack_counts.dart';
import '../model/lunch_packed_day.dart';
import '../model/lunch_pantry_bias.dart';
import '../model/lunch_pantry_entry.dart';
import '../model/lunch_pantry_week.dart';
import '../model/lunch_week.dart';
import 'lunch_pantry_groceries.dart';

/// The pantry (lunch-box ADR-0006): what is in the house, held against the
/// week the lunch board is on. Two reads of its own — the entries and the
/// boxes marked packed that week — joined with the board the lunch
/// controller already publishes, so the pantry never reads the plans twice.
///
/// It also holds whether the board is planning from the pantry: view state
/// (`FE-07`), off until somebody turns it on, and forgotten with the screen.
final class LunchPantryController extends ChangeNotifier
    with ActionFailureHolder {
  LunchPantryController({
    required LunchPantryRepository pantryRepository,
    required LunchRepository lunchRepository,
    required this.groceries,
    required this.householdId,
    required this.memberId,
  }) : _repository = pantryRepository,
       _lunches = lunchRepository {
    _entrySubscription = _repository
        .watchPantry(householdId)
        .listen(_onEntries, onError: _onError);
  }

  final LunchPantryRepository _repository;
  final LunchRepository _lunches;

  /// Sends what the week is missing to the grocery list.
  final LunchPantryGroceries groceries;
  final String householdId;

  /// Whose name every change goes in.
  final String memberId;

  late StreamSubscription<List<LunchPantryEntry>> _entrySubscription;
  StreamSubscription<List<LunchPackedDay>>? _packedSubscription;

  List<LunchPantryEntry>? _entries;
  List<LunchPackedDay>? _packed;
  AsyncState<LunchBoard> _board = const AsyncLoading();
  LunchWeek? _week;
  AppFailure? _readFailure;
  bool _isPlanningFromPantry = false;
  bool _isSending = false;
  AsyncState<LunchPantryWeek> _pantry = const AsyncLoading();

  AsyncState<LunchPantryWeek> get pantry => _pantry;

  bool get isPlanningFromPantry => _isPlanningFromPantry;

  /// The preference the picker and *Fill from the pantry* use — null until
  /// the pantry has been read, or while nobody is planning from it.
  LunchPantryBias? get bias => switch (_pantry) {
    AsyncData(:final value) when _isPlanningFromPantry => LunchPantryBias(
      value.availability,
    ),
    _ => null,
  };

  void setPlanningFromPantry({required bool isOn}) {
    if (isOn == _isPlanningFromPantry) return;
    _isPlanningFromPantry = isOn;
    notifyListeners();
  }

  /// The lunch board, as its controller last published it, and its week.
  void followBoard(AsyncState<LunchBoard> board, LunchWeek week) {
    if (week != _week) {
      _week = week;
      _packed = null;
      unawaited(_packedSubscription?.cancel());
      _packedSubscription = _repository
          .watchPacked(householdId, week)
          .listen((packed) => _onPacked(week, packed), onError: _onError);
    }
    if (identical(board, _board)) return;
    _board = board;
    _publish();
  }

  Future<void> setPortions(String itemId, int portions) => runAction(
    () => _repository.setPortions(
      householdId: householdId,
      itemId: itemId,
      portions: LunchPantryEntry.clamp(portions),
      by: memberId,
    ),
  );

  /// *A pack* more than there is — or a pack, for something not stocked.
  Future<void> addPack(String itemId) {
    final now = switch (_pantry) {
      AsyncData(:final value) => value.stockOf(itemId),
      _ => 0,
    };
    return setPortions(itemId, now + LunchPantryEntry.aPack);
  }

  Future<void> markUsedUp(String itemId) => setPortions(itemId, 0);

  /// Something the library does not have yet: added to it, then a pack of
  /// it stocked.
  Future<void> addNewAndStock(LunchItemDraft draft) => runAction(() async {
    final itemId = await _lunches.addItem(
      householdId,
      draft.toNewItem(memberId),
    );
    await _repository.setPortions(
      householdId: householdId,
      itemId: itemId,
      portions: LunchPantryEntry.aPack,
      by: memberId,
    );
  });

  Future<void> remove(String itemId) => runAction(
    () => _repository.remove(householdId: householdId, itemId: itemId),
  );

  /// Today's box is in the bag: the pantry gives up one of each thing in it
  /// that it holds, once (lunch-box ADR-0006).
  Future<void> markPacked({
    required String childId,
    required CalendarDate date,
    required LunchBox box,
  }) async {
    final pantry = _pantry;
    final week = _week;
    if (pantry is! AsyncData<LunchPantryWeek> || week == null) return;
    final (counts, taken) = LunchPackCounts.take(box, pantry.value);
    await _refusalAs(
      LunchPlanningProblem.alreadyPacked,
      () => _repository.markPacked(
        householdId: householdId,
        day: LunchPackedDay(
          id: LunchPackedDay.idFor(childId, date),
          childId: childId,
          date: date.iso,
          week: week.key,
          itemIds: taken,
          by: memberId,
        ),
        takeFrom: counts,
      ),
    );
  }

  /// Takes a *packed* back and returns what it took, to entries that are
  /// still in the pantry and have room.
  Future<void> unmarkPacked({
    required String childId,
    required CalendarDate date,
  }) async {
    final pantry = _pantry;
    final packed = _packed
        ?.where((day) => day.id == LunchPackedDay.idFor(childId, date))
        .firstOrNull;
    if (pantry is! AsyncData<LunchPantryWeek> || packed == null) return;
    await _refusalAs(
      LunchPlanningProblem.pantryChanged,
      () => _repository.unmarkPacked(
        householdId: householdId,
        day: packed.copyWith(by: memberId),
        giveBack: LunchPackCounts.giveBack(packed, pantry.value),
      ),
    );
  }

  /// Sends the week's shortfall to the grocery list; returns how many lines
  /// it added, or null when it did not get that far.
  Future<int?> sendShortfallToGroceries({
    required String Function(int boxes) quantityFor,
    required String Function(int boxes) noteFor,
  }) async {
    final pantry = _pantry;
    final week = _week;
    if (pantry is! AsyncData<LunchPantryWeek> || week == null || _isSending) {
      return null;
    }
    int? added;
    _isSending = true;
    notifyListeners();
    try {
      await runAction(() async {
        added = await groceries.add(
          pantry.value.shortfall,
          week: week,
          quantityFor: quantityFor,
          noteFor: noteFor,
        );
      });
    } finally {
      _isSending = false;
      notifyListeners();
    }
    return added;
  }

  /// True while the shortfall is on its way — it cannot be sent twice.
  bool get isSending => _isSending;

  Future<void> retry() async {
    await _cancel();
    _entries = null;
    _packed = null;
    _readFailure = null;
    _pantry = const AsyncLoading();
    final week = _week;
    _week = null;
    notifyListeners();
    _entrySubscription = _repository
        .watchPantry(householdId)
        .listen(_onEntries, onError: _onError);
    if (week != null) followBoard(_board, week);
  }

  Future<void> _refusalAs(
    LunchPlanningProblem problem,
    Future<void> Function() write,
  ) => runAction(() async {
    try {
      await write();
    } on PermissionDeniedFailure {
      throw LunchPlanningFailure(problem);
    }
  });

  void _onEntries(List<LunchPantryEntry> entries) {
    _entries = entries;
    _publish();
  }

  void _onPacked(LunchWeek week, List<LunchPackedDay> packed) {
    if (week != _week) return;
    _packed = packed;
    _publish();
  }

  void _publish() {
    final failure = _readFailure;
    final board = _board;
    final (entries, packed, week) = (_entries, _packed, _week);
    if (failure != null) {
      _pantry = AsyncFailure(failure);
    } else if (board is AsyncFailure<LunchBoard>) {
      _pantry = AsyncFailure(board.failure);
    } else if (board is AsyncData<LunchBoard> &&
        entries != null &&
        packed != null &&
        week != null) {
      _pantry = AsyncData(
        LunchPantryWeek.from(
          week: week,
          today: board.value.today,
          entries: entries,
          plans: [for (final child in board.value.children) child.plan],
          packed: packed,
          library: board.value.libraryById,
        ),
      );
    }
    notifyListeners();
  }

  void _onError(Object error) {
    _readFailure = error is AppFailure ? error : UnknownFailure(error);
    _publish();
  }

  Future<void> _cancel() async {
    await _entrySubscription.cancel();
    await _packedSubscription?.cancel();
    _packedSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
