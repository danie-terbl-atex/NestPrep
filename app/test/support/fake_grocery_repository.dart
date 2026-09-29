import 'dart:async';

import 'package:nestprep/features/groceries/data/grocery_repository.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_source.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Stands in for Firestore behind the controller, so a test drives the two live
/// streams by hand and nothing pumps the SDK (foundation ADR-0006).
final class FakeGroceryRepository implements GroceryRepository {
  final _items = StreamController<List<GroceryItem>>.broadcast();

  /// Set to make the next write fail, the way a rules denial does.
  AppFailure? failWritesWith;

  final added = <({String name, String? quantity, String addedBy})>[];
  final ticked = <({String itemId, bool isBought, String memberId})>[];
  final renamed = <({String itemId, String name, String? quantity})>[];
  final removed = <String>[];

  /// Where each added line came from, in the order they were added.
  final origins = <GrocerySource?>[];

  void emitItems(List<GroceryItem> items) => _items.add(items);
  void failItemsWith(Object error) => _items.addError(error);

  Future<void> close() => _items.close();

  @override
  Stream<List<GroceryItem>> watchItems(String householdId) => _items.stream;

  @override
  Future<void> add({
    required String householdId,
    required String name,
    String? quantity,
    required String addedBy,
    GrocerySource? origin,
  }) async {
    _refuseIfAsked();
    added.add((name: name, quantity: quantity, addedBy: addedBy));
    origins.add(origin);
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

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}
