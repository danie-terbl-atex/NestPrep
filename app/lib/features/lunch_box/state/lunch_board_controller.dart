import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../../family_profiles/model/family_roster.dart';
import '../data/lunch_repository.dart';
import '../model/lunch_auto_fill.dart';
import '../model/lunch_board.dart';
import '../model/lunch_favourite.dart';
import '../model/lunch_item.dart';
import '../model/lunch_plan.dart';
import '../model/lunch_prep.dart';
import '../model/lunch_prep_list.dart';
import '../model/lunch_seed_catalogue.dart';
import '../model/lunch_week.dart';
import '../model/lunch_week_items.dart';
import 'lunch_board_edits.dart';

/// The lunch screens' controller (lunch-box ADR-0001): the children from
/// family profiles, and four reads of this feature's own — the library, the
/// plans for this week and the eight before it, the go-to boxes, and the
/// week's prep ticks — joined into one `LunchBoard` and one `LunchPrepList`,
/// so a screen has one loading state (foundation ADR-0006).
///
/// It lives on the lunch shell, above the board, the prep list and the
/// library, so moving between them reopens nothing.
final class LunchBoardController extends ChangeNotifier
    with ActionFailureHolder {
  LunchBoardController({
    required LunchRepository lunchRepository,
    required HouseholdClock householdClock,
    required this.householdId,
    required this.memberId,
    required this.canEdit,
    LunchWeek? initialWeek,
  }) : _repository = lunchRepository,
       _clock = householdClock {
    _week = initialWeek ?? LunchWeek.planningFor(_clock.today);
    _subscribeToLibrary();
    _subscribeToWeek();
  }

  final LunchRepository _repository;
  final HouseholdClock _clock;
  final String householdId;

  /// Whose name the library's first items and every mark go in.
  final String memberId;

  /// The `lunch` grant at `edit` — only then is the library seeded.
  final bool canEdit;

  StreamSubscription<List<LunchItem>>? _itemSubscription;
  StreamSubscription<List<LunchFavourite>>? _favouriteSubscription;
  StreamSubscription<List<LunchPlan>>? _planSubscription;
  StreamSubscription<LunchPrep>? _prepSubscription;

  AsyncState<FamilyRoster> _roster = const AsyncLoading();
  List<LunchItem>? _items;
  List<LunchFavourite>? _favourites;
  List<LunchPlan>? _plans;
  LunchPrep? _prep;
  AppFailure? _readFailure;
  bool _hasAskedToSeed = false;

  late LunchWeek _week;
  String? _selectedChildId;
  AsyncState<LunchBoard> _board = const AsyncLoading();
  AsyncState<LunchPrepList> _prepList = const AsyncLoading();

  AsyncState<LunchBoard> get board => _board;
  AsyncState<LunchPrepList> get prepList => _prepList;
  LunchWeek get week => _week;
  CalendarDate get today => _clock.today;

  /// The child whose week is open; the first child until somebody chooses.
  String? get selectedChildId {
    final board = _board;
    if (board is! AsyncData<LunchBoard>) return _selectedChildId;
    final children = board.value.children;
    final chosen = children.where((c) => c.childId == _selectedChildId);
    return chosen.firstOrNull?.childId ?? children.firstOrNull?.childId;
  }

  /// What auto-fill last packed, for the screen to say once.
  LunchAutoFillResult? get lastAutoFill => edit.lastAutoFill;

  /// Every change a screen can make. Kept apart so this file stays about
  /// reading (`ENG-05`).
  late final LunchBoardEdits edit = LunchBoardEdits(
    lunchRepository: _repository,
    householdId: householdId,
    memberId: memberId,
    boardOf: () => _board,
    weekOf: () => _week,
    runAction: runAction,
    recordFailure: recordFailure,
    notify: notifyListeners,
  );

  /// The family's children and their rules, from family profiles' controller.
  void followRoster(AsyncState<FamilyRoster> roster) {
    if (identical(roster, _roster)) return;
    _roster = roster;
    _publish();
  }

  void selectChild(String childId) {
    if (childId == _selectedChildId) return;
    _selectedChildId = childId;
    notifyListeners();
  }

  void goToWeek(LunchWeek week) {
    if (week == _week) return;
    _week = week;
    _plans = null;
    _prep = null;
    _board = const AsyncLoading();
    _prepList = const AsyncLoading();
    notifyListeners();
    unawaited(_resubscribeToWeek());
  }

  void goToPreviousWeek() => goToWeek(_week.previous);
  void goToNextWeek() => goToWeek(_week.next);
  void goToThisWeek() => goToWeek(planningWeek);

  /// The week being planned today — see `LunchWeek.planningFor`.
  LunchWeek get planningWeek => LunchWeek.planningFor(today);

  Future<void> retry() async {
    await _cancel();
    _items = null;
    _favourites = null;
    _plans = null;
    _prep = null;
    _readFailure = null;
    _board = const AsyncLoading();
    _prepList = const AsyncLoading();
    notifyListeners();
    _subscribeToLibrary();
    _subscribeToWeek();
  }

  void _subscribeToLibrary() {
    _itemSubscription = _repository.watchItems(householdId).listen((items) {
      _items = items;
      _seedIfEmpty(items);
      _publish();
    }, onError: _onError);
    _favouriteSubscription = _repository.watchFavourites(householdId).listen((
      favourites,
    ) {
      _favourites = favourites;
      _publish();
    }, onError: _onError);
  }

  void _subscribeToWeek() {
    // A week left behind can still deliver one last emission before its
    // listener closes; it must not land on the week that replaced it.
    final week = _week;
    _planSubscription = _repository
        .watchPlans(
          householdId,
          from: week.shift(-LunchWeek.historyWeeks),
          to: week,
        )
        .listen((plans) {
          if (week != _week) return;
          _plans = plans;
          _publish();
        }, onError: _onError);
    _prepSubscription = _repository.watchPrep(householdId, week).listen((prep) {
      if (week != _week) return;
      _prep = prep;
      _publish();
    }, onError: _onError);
  }

  Future<void> _resubscribeToWeek() async {
    await _planSubscription?.cancel();
    await _prepSubscription?.cancel();
    _subscribeToWeek();
  }

  /// A household's first visit writes the starter library, once, and only
  /// for somebody who may add to it (lunch-box ADR-0001).
  void _seedIfEmpty(List<LunchItem> items) {
    if (items.isNotEmpty || !canEdit || _hasAskedToSeed) return;
    _hasAskedToSeed = true;
    unawaited(_seedLibrary());
  }

  Future<void> _seedLibrary() => runAction(
    () => _repository.seedItems(
      householdId,
      LunchSeedCatalogue.itemsFor(memberId),
    ),
  );

  void _publish() {
    final failure = _readFailure;
    if (failure != null) {
      _board = AsyncFailure(failure);
      _prepList = AsyncFailure(failure);
      notifyListeners();
      return;
    }
    final (items, favourites, plans, prep) = (
      _items,
      _favourites,
      _plans,
      _prep,
    );
    // The prep list is the household's week and needs no child's rules, so
    // it does not wait on family profiles.
    if (items != null && plans != null && prep != null) {
      _prepList = AsyncData(
        LunchPrepList(
          week: _week,
          items: LunchWeekItems.from(
            plans: plans.where((plan) => plan.week == _week.key),
            library: items,
          ),
          prep: prep,
        ),
      );
    }
    final roster = _roster;
    if (roster is AsyncFailure<FamilyRoster>) {
      _board = AsyncFailure(roster.failure);
    } else if (roster is AsyncData<FamilyRoster> &&
        items != null &&
        favourites != null &&
        plans != null) {
      _board = AsyncData(
        LunchBoard.from(
          week: _week,
          today: today,
          roster: roster.value,
          library: items,
          favourites: favourites,
          plans: plans,
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
    await _itemSubscription?.cancel();
    await _favouriteSubscription?.cancel();
    await _planSubscription?.cancel();
    await _prepSubscription?.cancel();
    _itemSubscription = null;
    _favouriteSubscription = null;
    _planSubscription = null;
    _prepSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
