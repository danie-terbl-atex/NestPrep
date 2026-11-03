import 'package:nestprep/features/lunch_box/data/lunch_variety_store.dart';
import 'package:nestprep/features/lunch_box/model/lunch_variety.dart';
import 'package:nestprep/features/lunch_box/state/lunch_variety_choice.dart';

/// The variety choice this phone remembers, per household, in memory;
/// [failRead] answers as an unreadable store does.
final class FakeLunchVarietyStore implements LunchVarietyStore {
  final kept = <String, LunchVariety>{};
  var failRead = false;

  @override
  Future<LunchVariety?> read(String householdId) async =>
      failRead ? null : kept[householdId];

  @override
  Future<void> write(String householdId, LunchVariety variety) async =>
      kept[householdId] = variety;
}

/// The variety choice for [householdId], kept in [store].
LunchVarietyChoice lunchVarietyChoice(
  String householdId, {
  LunchVarietyStore? store,
}) => LunchVarietyChoice(
  store: store ?? FakeLunchVarietyStore(),
  householdId: householdId,
);
