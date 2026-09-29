import 'dart:async';

import 'package:nestprep/features/lunch_box/data/lunch_repository.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_prep.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Lunch boxes driven by hand: every read a stream a test emits into, and
/// every write recorded, so a test asserts what a tap asked the backend to do
/// (`FE-20`). The plans stream is recreated when the window moves, so a test
/// can check the reopen.
final class FakeLunchRepository implements LunchRepository {
  final _items = StreamController<List<LunchItem>>.broadcast();
  final _favourites = StreamController<List<LunchFavourite>>.broadcast();
  StreamController<List<LunchPlan>> _plans =
      StreamController<List<LunchPlan>>.broadcast();
  StreamController<LunchPrep> _prep = StreamController<LunchPrep>.broadcast();
  final _plan = StreamController<LunchPlan>.broadcast();

  /// Set to make the next write fail the way a rules denial does.
  AppFailure? failWritesWith;

  final watchedWindows = <({String from, String to})>[];
  final watchedPlans = <String>[];
  final seeded = <List<LunchItem>>[];
  final addedItems = <LunchItem>[];
  final updatedItems = <LunchItem>[];
  final archived = <({String itemId, bool archived})>[];
  final writtenPicks =
      <({String childId, String week, Map<String, LunchPick?> picks})>[];
  final writtenFeedback =
      <({String childId, String week, int day, LunchFeedback? feedback})>[];
  final addedFavourites = <LunchFavourite>[];
  final deletedFavourites = <String>[];
  final prepTicks = <({String week, String itemId, bool done})>[];

  void emitItems(List<LunchItem> items) => _items.add(items);
  void emitFavourites(List<LunchFavourite> favourites) =>
      _favourites.add(favourites);
  void emitPlans(List<LunchPlan> plans) => _plans.add(plans);
  void emitPrep(LunchPrep prep) => _prep.add(prep);
  void emitPlan(LunchPlan plan) => _plan.add(plan);
  void failItemsWith(Object error) => _items.addError(error);
  void failPlanWith(Object error) => _plan.addError(error);

  Future<void> close() async {
    await _items.close();
    await _favourites.close();
    await _plans.close();
    await _prep.close();
    await _plan.close();
  }

  @override
  Stream<List<LunchItem>> watchItems(String householdId) => _items.stream;

  @override
  Stream<List<LunchPlan>> watchPlans(
    String householdId, {
    required LunchWeek from,
    required LunchWeek to,
  }) {
    watchedWindows.add((from: from.key, to: to.key));
    if (_plans.hasListener) {
      _plans = StreamController<List<LunchPlan>>.broadcast();
    }
    return _plans.stream;
  }

  @override
  Stream<LunchPlan> watchPlan(
    String householdId, {
    required String childId,
    required LunchWeek week,
  }) {
    watchedPlans.add(LunchPlan.idFor(childId, week));
    return _plan.stream;
  }

  @override
  Stream<List<LunchFavourite>> watchFavourites(String householdId) =>
      _favourites.stream;

  @override
  Stream<LunchPrep> watchPrep(String householdId, LunchWeek week) {
    if (_prep.hasListener) _prep = StreamController<LunchPrep>.broadcast();
    return _prep.stream;
  }

  @override
  Future<void> seedItems(String householdId, List<LunchItem> items) async {
    _refuseIfAsked();
    seeded.add(items);
  }

  @override
  Future<String> addItem(String householdId, LunchItem item) async {
    _refuseIfAsked();
    addedItems.add(item);
    return 'item-${addedItems.length}';
  }

  @override
  Future<void> updateItem(String householdId, LunchItem item) async {
    _refuseIfAsked();
    updatedItems.add(item);
  }

  @override
  Future<void> setItemArchived({
    required String householdId,
    required String itemId,
    required bool archived,
  }) async {
    _refuseIfAsked();
    this.archived.add((itemId: itemId, archived: archived));
  }

  @override
  Future<void> setPicks({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required Map<String, LunchPick?> picks,
  }) async {
    _refuseIfAsked();
    writtenPicks.add((childId: childId, week: week.key, picks: picks));
  }

  @override
  Future<void> setFeedback({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required LunchFeedback? feedback,
  }) async {
    _refuseIfAsked();
    writtenFeedback.add((
      childId: childId,
      week: week.key,
      day: isoWeekday,
      feedback: feedback,
    ));
  }

  @override
  Future<String> addFavourite(
    String householdId,
    LunchFavourite favourite,
  ) async {
    _refuseIfAsked();
    addedFavourites.add(favourite);
    return 'fav-${addedFavourites.length}';
  }

  @override
  Future<void> deleteFavourite({
    required String householdId,
    required String favouriteId,
  }) async {
    _refuseIfAsked();
    deletedFavourites.add(favouriteId);
  }

  @override
  Future<void> setPrepDone({
    required String householdId,
    required LunchWeek week,
    required String itemId,
    required bool done,
  }) async {
    _refuseIfAsked();
    prepTicks.add((week: week.key, itemId: itemId, done: done));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}
