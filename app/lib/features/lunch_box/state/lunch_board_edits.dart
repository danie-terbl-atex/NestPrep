import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../family_profiles/model/food_rules.dart';
import '../data/lunch_repository.dart';
import '../model/lunch_auto_fill.dart';
import '../model/lunch_board.dart';
import '../model/lunch_box.dart';
import '../model/lunch_favourite.dart';
import '../model/lunch_feedback.dart';
import '../model/lunch_fill_bias.dart';
import '../model/lunch_item.dart';
import '../model/lunch_item_draft.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_plan.dart';
import '../model/lunch_safety.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_week.dart';

/// Every change the lunch screens make, one method each (lunch-box
/// ADR-0001). It holds nothing the listeners do not also hold; it reads the
/// board the controller last published and writes through the repository.
///
/// Safety is checked here before anything is written, so the person hears
/// why in words about the child. The rules check it again, and theirs is the
/// answer that counts (`FE-04`, `BE-20`).
final class LunchBoardEdits {
  LunchBoardEdits({
    required LunchRepository lunchRepository,
    required this.householdId,
    required this.memberId,
    required this._boardOf,
    required this._weekOf,
    required this._runAction,
    required this._recordFailure,
    required this._notify,
  }) : _repository = lunchRepository;

  final LunchRepository _repository;
  final String householdId;
  final String memberId;
  final AsyncState<LunchBoard> Function() _boardOf;
  final LunchWeek Function() _weekOf;
  final Future<void> Function(Future<void> Function() action) _runAction;
  final void Function(AppFailure? failure) _recordFailure;
  final void Function() _notify;

  bool _isFilling = false;
  LunchAutoFillResult? _lastAutoFill;

  /// True while a week is being auto-filled — it cannot be asked twice.
  bool get isFilling => _isFilling;

  LunchAutoFillResult? get lastAutoFill => _lastAutoFill;

  void dismissAutoFill() {
    if (_lastAutoFill == null) return;
    _lastAutoFill = null;
    _notify();
  }

  LunchChildWeek? _childWeek(String childId) => switch (_boardOf()) {
    AsyncData(:final value) => value.childWeek(childId),
    _ => null,
  };

  FoodRules? _rulesOf(String childId) => _childWeek(childId)?.child.foodRules;

  /// Puts [item] in one slot of one child's box, unless it is not safe for
  /// them.
  Future<void> pick({
    required String childId,
    required int isoWeekday,
    required LunchItem item,
  }) => packAcross(childId: childId, weekdays: [isoWeekday], item: item);

  /// Adds something the household has not had before, then packs it — or,
  /// when it is not safe for this child, only adds it.
  Future<void> addAndPick({
    required String childId,
    required int isoWeekday,
    required LunchItemDraft draft,
  }) => _runAction(() async {
    final item = draft.toNewItem(memberId);
    final id = await _repository.addItem(householdId, item);
    final pick = LunchPick.of(item.copyWith(id: id));
    if (!_isSafeFor(childId, [pick])) return;
    await _writeNow(childId, {LunchPlan.slotKey(isoWeekday, draft.slot): pick});
  });

  Future<void> clear({
    required String childId,
    required int isoWeekday,
    required LunchSlot slot,
  }) => _write(childId, {LunchPlan.slotKey(isoWeekday, slot): null});

  Future<void> clearDay({required String childId, required int isoWeekday}) =>
      _write(childId, {
        for (final slot in LunchSlot.values)
          LunchPlan.slotKey(isoWeekday, slot): null,
      });

  /// Packs a go-to box into one day, replacing what was there.
  Future<void> packFavourite({
    required String childId,
    required int isoWeekday,
    required LunchFavourite favourite,
  }) async {
    final board = _boardOf();
    final library = board is AsyncData<LunchBoard>
        ? board.value.libraryById
        : const <String, LunchItem>{};
    final box = favourite.box;
    final picks = {
      for (final slot in LunchSlot.values)
        LunchPlan.slotKey(isoWeekday, slot): switch (box[slot]) {
          null => null,
          final pick => switch (library[pick.itemId]) {
            null => pick,
            final item => LunchPick.of(item),
          },
        },
    };
    if (!_isSafeFor(childId, picks.values.whereType<LunchPick>())) return;
    await _write(childId, picks);
  }

  /// Fills the empty parts of a child's week from their favourites and what
  /// they eat (lunch-box ADR-0003) — preferring what the pantry has when
  /// planning from it ([bias], lunch-box ADR-0006).
  Future<void> autoFill(String childId, {LunchFillBias? bias}) async {
    final board = _boardOf();
    final childWeek = _childWeek(childId);
    if (_isFilling || board is! AsyncData<LunchBoard> || childWeek == null) {
      return;
    }
    final result = LunchAutoFill.fill(
      plan: childWeek.plan,
      week: board.value.week,
      favourites: childWeek.favourites,
      library: board.value.library,
      rules: childWeek.child.foodRules,
      taste: childWeek.taste,
      bias: bias,
    );
    _isFilling = true;
    _lastAutoFill = null;
    _notify();
    try {
      await _runAction(() async {
        if (!result.isEmpty) await _writeNow(childId, result.picks);
        _lastAutoFill = result;
      });
    } finally {
      _isFilling = false;
      _notify();
    }
  }

  /// Puts [item] in its slot on each of [weekdays], in one write — a cheaper
  /// swap across a week (lunch-box ADR-0007).
  Future<void> packAcross({
    required String childId,
    required List<int> weekdays,
    required LunchItem item,
  }) async {
    final slot = item.slot;
    if (slot == null || weekdays.isEmpty) return;
    if (!_isSafeFor(childId, [LunchPick.of(item)])) return;
    await _write(childId, {
      for (final day in weekdays)
        LunchPlan.slotKey(day, slot): LunchPick.of(item),
    });
  }

  Future<void> saveFavourite({
    required String childId,
    required String name,
    required LunchBox box,
  }) async {
    final trimmed = name.trim();
    final childWeek = _childWeek(childId);
    if (trimmed.isEmpty || box.isEmpty || childWeek == null) return;
    if (trimmed.length > LunchFavourite.nameLimit) {
      _recordFailure(const LunchFailure(LunchProblem.nameTooLong));
      return;
    }
    if (childWeek.favourites.length >= LunchFavourite.perChildLimit) {
      _recordFailure(const LunchFailure(LunchProblem.tooManyFavourites));
      return;
    }
    await _runAction(
      () => _repository.addFavourite(
        householdId,
        LunchFavourite.of(
          id: '',
          childId: childId,
          name: trimmed,
          box: box,
          createdBy: memberId,
        ),
      ),
    );
  }

  Future<void> deleteFavourite(String favouriteId) => _runAction(
    () => _repository.deleteFavourite(
      householdId: householdId,
      favouriteId: favouriteId,
    ),
  );

  /// Thumbs up or down for a day's box, and optionally for what was in it.
  Future<void> markEaten({
    required String childId,
    required int isoWeekday,
    required LunchVerdict box,
    Map<LunchSlot, LunchVerdict> items = const {},
  }) => _runAction(
    () => _repository.setFeedback(
      householdId: householdId,
      childId: childId,
      week: _weekOf(),
      isoWeekday: isoWeekday,
      feedback: LunchFeedback.of(box: box, items: items, by: memberId),
    ),
  );

  Future<void> unmarkEaten({
    required String childId,
    required int isoWeekday,
  }) => _runAction(
    () => _repository.setFeedback(
      householdId: householdId,
      childId: childId,
      week: _weekOf(),
      isoWeekday: isoWeekday,
      feedback: null,
    ),
  );

  Future<void> addItem(LunchItemDraft draft) => _runAction(
    () => _repository.addItem(householdId, draft.toNewItem(memberId)),
  );

  Future<void> updateItem(LunchItem item, LunchItemDraft draft) => _runAction(
    () => _repository.updateItem(householdId, draft.applyTo(item)),
  );

  Future<void> setArchived(String itemId, {required bool archived}) =>
      _runAction(
        () => _repository.setItemArchived(
          householdId: householdId,
          itemId: itemId,
          archived: archived,
        ),
      );

  Future<void> setPrepped(String itemId, {required bool done}) => _runAction(
    () => _repository.setPrepDone(
      householdId: householdId,
      week: _weekOf(),
      itemId: itemId,
      done: done,
    ),
  );

  bool _isSafeFor(String childId, Iterable<LunchPick> picks) {
    final rules = _rulesOf(childId);
    if (rules == null) return false;
    final isSafe = picks.every(
      (pick) =>
          LunchSafety.isSafe(allergens: pick.knownAllergens, rules: rules),
    );
    if (!isSafe) {
      _recordFailure(const LunchFailure(LunchProblem.unsafeForChild));
    }
    return isSafe;
  }

  Future<void> _write(String childId, Map<String, LunchPick?> picks) =>
      _runAction(() => _writeNow(childId, picks));

  /// A refusal here is the rules saying the box is unsafe after all — the
  /// child's rules changed on another phone since this one last heard.
  Future<void> _writeNow(String childId, Map<String, LunchPick?> picks) async {
    try {
      await _repository.setPicks(
        householdId: householdId,
        childId: childId,
        week: _weekOf(),
        picks: picks,
      );
    } on PermissionDeniedFailure {
      throw const LunchFailure(LunchProblem.refusedByRules);
    }
  }
}
