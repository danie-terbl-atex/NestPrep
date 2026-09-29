import 'dart:async';

import 'package:nestprep/features/groceries/data/grocery_suggestion_source.dart';
import 'package:nestprep/features/groceries/model/grocery_need.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';

/// A `GrocerySuggestionSource` driven by hand — the plans, or a plug-in such
/// as home-care's stock tracker (groceries ADR-0004).
final class FakeGrocerySource implements GrocerySuggestionSource {
  FakeGrocerySource({required this.id, required this.area});

  @override
  final String id;

  @override
  final HouseholdArea area;

  final _needs = StreamController<List<GroceryNeed>>.broadcast();
  final watchedWeeks = <String>[];

  void emit(List<GroceryNeed> needs) => _needs.add(needs);
  void fail(Object error) => _needs.addError(error);

  Future<void> close() => _needs.close();

  @override
  Stream<List<GroceryNeed>> watchNeeds(String householdId, LunchWeek week) {
    watchedWeeks.add(week.key);
    return _needs.stream;
  }
}
