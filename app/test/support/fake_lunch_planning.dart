import 'dart:async';

import 'package:nestprep/features/lunch_box/data/lunch_budget_repository.dart';
import 'package:nestprep/features/lunch_box/data/lunch_choices_repository.dart';
import 'package:nestprep/features/lunch_box/data/lunch_pantry_repository.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_packed_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Lunch-box's V2 repositories driven by hand (lunch-box ADR-0006 to
/// ADR-0008): every read a stream a test emits into, every write recorded.
final class FakeLunchPantryRepository implements LunchPantryRepository {
  final _pantry = StreamController<List<LunchPantryEntry>>.broadcast();
  final _packed = StreamController<List<LunchPackedDay>>.broadcast();

  AppFailure? failWritesWith;

  final watchedWeeks = <String>[];
  final portions = <({String itemId, int portions})>[];
  final removed = <String>[];
  final packedWrites = <({LunchPackedDay day, Map<String, int> takeFrom})>[];
  final unpacked = <({LunchPackedDay day, Map<String, int> giveBack})>[];

  void emitPantry(List<LunchPantryEntry> entries) => _pantry.add(entries);
  void emitPacked(List<LunchPackedDay> days) => _packed.add(days);
  void failPantryWith(Object error) => _pantry.addError(error);

  Future<void> close() async {
    await _pantry.close();
    await _packed.close();
  }

  @override
  Stream<List<LunchPantryEntry>> watchPantry(String householdId) =>
      _pantry.stream;

  @override
  Stream<List<LunchPackedDay>> watchPacked(String householdId, LunchWeek week) {
    watchedWeeks.add(week.key);
    return _packed.stream;
  }

  @override
  Future<void> setPortions({
    required String householdId,
    required String itemId,
    required int portions,
    required String by,
  }) async {
    _refuseIfAsked();
    this.portions.add((itemId: itemId, portions: portions));
  }

  @override
  Future<void> remove({
    required String householdId,
    required String itemId,
  }) async {
    _refuseIfAsked();
    removed.add(itemId);
  }

  @override
  Future<void> markPacked({
    required String householdId,
    required LunchPackedDay day,
    required Map<String, int> takeFrom,
  }) async {
    _refuseIfAsked();
    packedWrites.add((day: day, takeFrom: takeFrom));
  }

  @override
  Future<void> unmarkPacked({
    required String householdId,
    required LunchPackedDay day,
    required Map<String, int> giveBack,
  }) async {
    _refuseIfAsked();
    unpacked.add((day: day, giveBack: giveBack));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}

final class FakeLunchBudgetRepository implements LunchBudgetRepository {
  final _prices = StreamController<List<LunchPrice>>.broadcast();
  final _budget = StreamController<LunchBudget?>.broadcast();

  AppFailure? failWritesWith;

  final setPrices = <LunchPrice>[];
  final clearedPrices = <String>[];
  final setBudgets = <LunchBudget>[];
  var budgetsCleared = 0;

  void emitPrices(List<LunchPrice> prices) => _prices.add(prices);
  void emitBudget(LunchBudget? budget) => _budget.add(budget);
  void failPricesWith(Object error) => _prices.addError(error);

  Future<void> close() async {
    await _prices.close();
    await _budget.close();
  }

  @override
  Stream<List<LunchPrice>> watchPrices(String householdId) => _prices.stream;

  @override
  Stream<LunchBudget?> watchBudget(String householdId) => _budget.stream;

  @override
  Future<void> setPrice(String householdId, LunchPrice price) async {
    _refuseIfAsked();
    setPrices.add(price);
  }

  @override
  Future<void> clearPrice({
    required String householdId,
    required String itemId,
  }) async {
    _refuseIfAsked();
    clearedPrices.add(itemId);
  }

  @override
  Future<void> setBudget(String householdId, LunchBudget budget) async {
    _refuseIfAsked();
    setBudgets.add(budget);
  }

  @override
  Future<void> clearBudget(String householdId) async {
    _refuseIfAsked();
    budgetsCleared++;
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}

final class FakeLunchChoicesRepository implements LunchChoicesRepository {
  final _week = StreamController<List<LunchChoices>>.broadcast();
  final _choices = StreamController<LunchChoices>.broadcast();

  AppFailure? failWritesWith;

  final watchedWeeks = <String>[];
  final watchedChoices = <String>[];
  final setOptionsWrites =
      <({String childId, int day, Map<String, List<LunchPick>?> options})>[];
  final chosen =
      <({String childId, int day, LunchSlot slot, LunchPick pick})>[];

  void emitWeek(List<LunchChoices> choices) => _week.add(choices);
  void emitChoices(LunchChoices choices) => _choices.add(choices);
  void failChoicesWith(Object error) => _choices.addError(error);

  Future<void> close() async {
    await _week.close();
    await _choices.close();
  }

  @override
  Stream<List<LunchChoices>> watchWeek(String householdId, LunchWeek week) {
    watchedWeeks.add(week.key);
    return _week.stream;
  }

  @override
  Stream<LunchChoices> watchChoices(
    String householdId, {
    required String childId,
    required LunchWeek week,
  }) {
    watchedChoices.add('${childId}_${week.key}');
    return _choices.stream;
  }

  @override
  Future<void> setOptions({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required Map<String, List<LunchPick>?> options,
    required String by,
  }) async {
    _refuseIfAsked();
    setOptionsWrites.add((childId: childId, day: isoWeekday, options: options));
  }

  @override
  Future<void> choose({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required LunchSlot slot,
    required LunchPick pick,
  }) async {
    _refuseIfAsked();
    chosen.add((childId: childId, day: isoWeekday, slot: slot, pick: pick));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}
