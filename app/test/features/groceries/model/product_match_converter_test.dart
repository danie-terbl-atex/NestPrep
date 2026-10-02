import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/groceries/model/product_match_converter.dart';
import 'package:nestprep/shared/money/money.dart';

/// The `productMatch` field as the Checkers build contract fixes it.
Map<String, Object?> storedMatch() => {
  'retailer': 'checkers',
  'productId': '5d3af63bf434cf8420737dd6',
  'articleCode': '10136729EA',
  'unitOfMeasure': 'EA',
  'name': 'Clover Fresh Full Cream Milk 2L',
  'brand': 'Clover',
  'priceCents': 3799,
  'currency': 'ZAR',
  'imageId': '6a5973a6f76689d8c79e254f',
  'pickedBy': 'member-sam',
  'pickedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 30, 12)),
};

void main() {
  const converter = ProductMatchConverter();

  test('a stored pick reads with its price as money', () {
    final match = converter.fromJson(storedMatch())!;
    expect(match.retailer, ProductRetailer.checkers);
    expect(match.price, const Money(3799));
    expect(match.pickedAt, DateTime.utc(2026, 9, 30, 12));
    expect(match.isSoldByWeight, isFalse);
  });

  test(
    'a pick is written in the contract’s shape, the server’s time on it',
    () {
      final match = converter.fromJson(storedMatch())!.copyWith(pickedAt: null);
      final written = converter.toJson(match)! as Map<String, Object?>;
      expect(written.keys, storedMatch().keys);
      expect(written['priceCents'], 3799);
      expect(written['currency'], 'ZAR');
      expect(written['pickedAt'], isA<FieldValue>());
    },
  );

  test('a pick of the wrong shape reads as none, and the item still reads', () {
    final item = GroceryItem.fromJson({
      'id': 'i',
      'name': 'Milk',
      'addedBy': 'member-sam',
      'productMatch': {'retailer': 'checkers', 'priceCents': 'a lot'},
    });
    expect(item.name, 'Milk');
    expect(item.productMatch, isNull);
  });

  test('a new item writes no productMatch at all', () {
    const item = GroceryItem(id: 'i', name: 'Milk', addedBy: 'member-sam');
    expect(item.toJson().containsKey('productMatch'), isFalse);
  });

  test('a retailer this build does not know reads as no pick', () {
    expect(converter.fromJson({...storedMatch(), 'retailer': 'pnp'}), isNull);
  });
}
