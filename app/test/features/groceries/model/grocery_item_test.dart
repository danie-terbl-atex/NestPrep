import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';

void main() {
  final now = DateTime.utc(2026, 9, 17, 12);

  group('what the list still shows', () {
    test('keeps an unbought item forever', () {
      const item = GroceryItem(id: 'i', name: 'Milk', addedBy: 'm-sam');
      expect(item.isBought, isFalse);
      expect(item.isStillVisible(now), isTrue);
    });

    test('keeps a bought item for a day, struck through, so a wrong tick can be undone', () {
      final justBought = GroceryItem(
        id: 'i',
        name: 'Milk',
        addedBy: 'm-sam',
        boughtAt: now.subtract(const Duration(hours: 23, minutes: 59)),
      );
      expect(justBought.isBought, isTrue);
      expect(justBought.isStillVisible(now), isTrue);
    });

    test('drops a bought item after a day without deleting it', () {
      final yesterday = GroceryItem(
        id: 'i',
        name: 'Milk',
        addedBy: 'm-sam',
        boughtAt: now.subtract(const Duration(hours: 24, minutes: 1)),
      );
      expect(yesterday.isStillVisible(now), isFalse);
      expect(yesterday.isBought, isTrue);
    });
  });

  group('the stored shape', () {
    test('round-trips through Firestore without writing its own id', () {
      final item = GroceryItem(
        id: 'i',
        name: 'Milk',
        quantity: '2 l',
        addedBy: 'm-sam',
        addedAt: now,
      );
      final json = item.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(GroceryItem.fromJson({...json, 'id': 'i'}), item);
    });

    test('a pending timestamp is written as the server"s, not the device"s', () {
      const item = GroceryItem(id: 'i', name: 'Milk', addedBy: 'm-sam');
      // Null on write means "the server decides", which is what lets the rules
      // insist on request.time (foundation ADR-0002).
      expect(item.toJson()['addedAt'], isA<FieldValue>());
    });

    test('reads an older document that predates the quantity field', () {
      final item = GroceryItem.fromJson({
        'id': 'i',
        'name': 'Milk',
        'addedBy': 'm-sam',
      });
      expect(item.quantity, isNull);
      expect(item.boughtAt, isNull);
    });
  });
}
