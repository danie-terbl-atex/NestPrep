import 'dart:async';

import 'package:nestprep/features/groceries/data/grocery_repository.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_changes.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_settings.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Stands in for Firestore behind the controller, so a test drives the two live
/// streams by hand and nothing pumps the SDK (foundation ADR-0006).
///
/// With [echoPlanWrites] on it behaves like the offline cache: a plan write
/// changes [items] and the list emits again, which is what keep-in-step and the
/// flow tests need to see their own writes arrive.
final class FakeGroceryRepository implements GroceryRepository {
  FakeGroceryRepository({this.echoPlanWrites = false});

  final bool echoPlanWrites;

  final _items = StreamController<List<GroceryItem>>.broadcast();
  final _settings = StreamController<GroceryPlanSettings>.broadcast();

  /// Set to make the next write fail, the way a rules denial does.
  AppFailure? failWritesWith;

  /// The list as the fake last emitted it.
  var items = <GroceryItem>[];

  /// The settings as the fake last emitted them.
  var settings = GroceryPlanSettings.empty;

  final added = <({String name, String? quantity, String addedBy})>[];
  final ticked = <({String itemId, bool isBought, String memberId})>[];
  final renamed = <({String itemId, String name, String? quantity})>[];
  final removed = <String>[];
  final planChanges = <({GroceryPlanChanges changes, String memberId})>[];
  final keepInStepWrites = <bool>[];
  final stapleWrites = <({String key, bool isStaple})>[];

  void emitItems(List<GroceryItem> value) {
    items = value;
    _items.add(value);
  }

  void emitSettings(GroceryPlanSettings value) {
    settings = value;
    _settings.add(value);
  }

  void failItemsWith(Object error) => _items.addError(error);
  void failSettingsWith(Object error) => _settings.addError(error);

  Future<void> close() async {
    await _items.close();
    await _settings.close();
  }

  @override
  Stream<List<GroceryItem>> watchItems(String householdId) => _items.stream;

  @override
  Stream<GroceryPlanSettings> watchPlanSettings(String householdId) =>
      _settings.stream;

  @override
  Future<void> add({
    required String householdId,
    required String name,
    String? quantity,
    required String addedBy,
  }) async {
    _refuseIfAsked();
    added.add((name: name, quantity: quantity, addedBy: addedBy));
  }

  @override
  Future<void> setBought({
    required String householdId,
    required String itemId,
    required bool isBought,
    required String memberId,
  }) async {
    _refuseIfAsked();
    ticked.add((itemId: itemId, isBought: isBought, memberId: memberId));
  }

  @override
  Future<void> rename({
    required String householdId,
    required String itemId,
    required String name,
    String? quantity,
  }) async {
    _refuseIfAsked();
    renamed.add((itemId: itemId, name: name, quantity: quantity));
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
  Future<void> applyPlanChanges({
    required String householdId,
    required GroceryPlanChanges changes,
    required String memberId,
  }) async {
    _refuseIfAsked();
    planChanges.add((changes: changes, memberId: memberId));
    if (echoPlanWrites) emitItems(_applied(changes, memberId));
  }

  @override
  Future<void> setKeepInStep({
    required String householdId,
    required bool keepInStep,
    required String memberId,
  }) async {
    _refuseIfAsked();
    keepInStepWrites.add(keepInStep);
    if (echoPlanWrites) {
      emitSettings(
        settings.copyWith(keepInStep: keepInStep, updatedBy: memberId),
      );
    }
  }

  @override
  Future<void> setStaple({
    required String householdId,
    required String key,
    required bool isStaple,
    required String memberId,
  }) async {
    _refuseIfAsked();
    stapleWrites.add((key: key, isStaple: isStaple));
    if (echoPlanWrites) {
      final staples = {...settings.staples};
      isStaple ? staples.add(key) : staples.remove(key);
      emitSettings(settings.copyWith(staples: staples.toList()));
    }
  }

  List<GroceryItem> _applied(GroceryPlanChanges changes, String memberId) {
    final refreshed = {
      for (final refresh in changes.refreshes) refresh.itemId: refresh,
    };
    return [
      for (final create in changes.creates)
        GroceryItem(
          id: create.id,
          name: create.name,
          quantity: create.quantity,
          addedBy: memberId,
          sourceKey: create.key,
          sourceWeek: create.week,
          sourceNote: create.note,
        ),
      for (final item in items)
        if (!changes.removals.contains(item.id))
          switch (refreshed[item.id]) {
            final refresh? => item.copyWith(
              quantity: refresh.quantity,
              sourceNote: refresh.note,
            ),
            null => item,
          },
    ];
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}
