import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_catalogue_parser.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Real Sixty60 answers, captured on 2026-09-30 from the unauthenticated
/// catalogue near central Cape Town and trimmed to the fields that matter.
Object? fixture(String name) => jsonDecode(
  File('test/features/add_to_checkers/fixtures/$name.json').readAsStringSync(),
);

void main() {
  test('only the stores that deliver within the hour are kept', () {
    final stores = CheckersCatalogueParser.sixtyMinuteStores(
      fixture('store_contexts_cape_town'),
    );
    expect(
      [for (final store in stores) store.storeId],
      ['62dabedd2aa38c342af94d53', '62dabd7f832d656087c747d8'],
    );
    expect(stores.first.brandPriority, 7);
  });

  test('a product reads as name, brand, cents and stock, best match first', () {
    final products = CheckersCatalogueParser.products(
      fixture('products_filter_milk'),
    );
    expect(products, hasLength(5));
    final first = products.first;
    expect(first.id, '5d3af63bf434cf8420737dd6');
    expect(first.name, 'Clover Fresh Full Cream Milk 2L');
    expect(first.brand, 'Clover');
    expect(first.price.cents, 3799);
    expect(first.articleCode, '10136729EA');
    expect(first.isInStock, isTrue);
    expect(first.imageId, '6a5973a6f76689d8c79e254f');
  });

  test('an "old price" equal to today’s is not a reduction', () {
    final first = CheckersCatalogueParser.products(
      fixture('products_filter_milk'),
    ).first;
    expect(first.oldPrice, isNull);
  });

  test('a unit Checkers adds later, like a pack, is kept as it is sent', () {
    final products = CheckersCatalogueParser.products(
      fixture('products_filter_milk'),
    );
    expect(products[2].unitOfMeasure, 'PK1');
    expect(products[2].isSoldByWeight, isFalse);
  });

  test('a weighed product is priced per kilogram and says so', () {
    final products = CheckersCatalogueParser.products(
      fixture('products_filter_chicken_breast'),
    );
    expect(products.first.unitOfMeasure, 'KG');
    expect(products.first.isSoldByWeight, isTrue);
    expect(products.first.price.cents, 9999);
    expect(products[2].isOnPromotion, isTrue);
  });

  test('a higher old price is a was-price', () {
    final products = CheckersCatalogueParser.products({
      'products': [
        {
          'id': 'a',
          'storeId': 's',
          'articleNumber': '1',
          'unitOfMeasure': 'EA',
          'displayName': 'Bread',
          'priceWithoutDecimal': 1599,
          'oldPrice': 1899,
          'isOnPromotion': true,
          'isStockAvailable': false,
        },
      ],
    });
    expect(products.single.oldPrice?.cents, 1899);
    expect(products.single.isInStock, isFalse);
    expect(products.single.brand, isNull);
  });

  test('one odd product is left out, never the other four', () {
    final products = CheckersCatalogueParser.products({
      'products': [
        {'id': 'no-price', 'storeId': 's', 'articleNumber': '1'},
        {
          'id': 'ok',
          'storeId': 's',
          'articleNumber': '2',
          'unitOfMeasure': 'EA',
          'name': 'Eggs',
          'priceWithoutDecimal': 4299,
        },
      ],
    });
    expect([for (final product in products) product.id], ['ok']);
  });

  test('an answer of the wrong shape is "Checkers changed", not a crash', () {
    expect(
      () => CheckersCatalogueParser.products({'items': <Object?>[]}),
      throwsA(
        isA<CheckersFailure>().having(
          (failure) => failure.problem,
          'problem',
          CheckersProblem.catalogueChanged,
        ),
      ),
    );
    expect(
      () => CheckersCatalogueParser.sixtyMinuteStores('nope'),
      throwsA(isA<CheckersFailure>()),
    );
  });

  group('what the shop says is in it (lunch-box ADR-0012)', () {
    test('reads the Allergens and Ingredients lines as plain text', () {
      final smooth = CheckersCatalogueParser.products(
        fixture('products_filter_peanut_butter'),
      ).first;
      expect(smooth.allergenText, 'Contains: Peanuts, Soya.');
      expect(smooth.ingredientsText, startsWith('Peanuts (90%), Sugar'));
      expect(smooth.hasContentsText, isTrue);
      expect(smooth.packCount, isNull);
    });

    test('a product with neither line says nothing about its contents', () {
      final crunchy = CheckersCatalogueParser.products(
        fixture('products_filter_peanut_butter'),
      )[1];
      expect(crunchy.allergenText, isNull);
      expect(crunchy.ingredientsText, isNull);
      expect(crunchy.hasContentsText, isFalse);
    });

    test('HTML in an attribute is taken out', () {
      final product = CheckersCatalogueParser.products({
        'products': [
          {
            'id': 'a',
            'storeId': 's',
            'articleNumber': '1',
            'unitOfMeasure': 'EA',
            'name': 'Yoghurt',
            'priceWithoutDecimal': 100,
            'attributes': [
              {
                'name': 'Ingredients',
                'value': '<ul><li>Milk</li><li>Fruit &amp; sugar</li></ul>',
              },
            ],
          },
        ],
      }).single;
      expect(product.ingredientsText, 'Milk Fruit & sugar');
    });

    test('a pack size is read only when the shop says it plainly', () {
      List<int?> counts(List<Map<String, Object?>> extras) => [
        for (final product in CheckersCatalogueParser.products({
          'products': [
            for (final (index, extra) in extras.indexed)
              {
                'id': 'p$index',
                'storeId': 's',
                'articleNumber': '$index',
                'unitOfMeasure': 'EA',
                'name': 'Thing',
                'priceWithoutDecimal': 100,
                ...extra,
              },
          ],
        }))
          product.packCount,
      ];
      expect(
        counts([
          {'name': 'Yoghurt 6 x 100g'},
          {'packQuantity': 4},
          {'boxContent': '<p>8 x 30g juice boxes</p>'},
          {'name': 'Rusks 6-pack'},
          {'name': 'Bread 700g', 'boxContent': '1 x 700g Bread'},
          {'name': 'Milk 2L'},
        ]),
        [6, 4, 8, 6, null, null],
      );
    });
  });
}
