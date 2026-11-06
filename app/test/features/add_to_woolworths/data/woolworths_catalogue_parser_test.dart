import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_woolworths/data/woolworths_catalogue_parser.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_store.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

Object? fixture(String name) => jsonDecode(
  File('test/features/add_to_woolworths/fixtures/$name.json')
      .readAsStringSync(),
);

Matcher refusedAs(WoolworthsProblem problem) => throwsA(
  isA<WoolworthsFailure>().having((f) => f.problem, 'problem', problem),
);

void main() {
  const rosebank = WoolworthsStore(id: '475', priceZone: 'p30');

  group('validatePlace', () {
    test('names the store and the price list it reads', () {
      expect(
        WoolworthsCatalogueParser.store(fixture('validate_place')),
        rosebank,
      );
    });

    test('each price list reads its own price field', () {
      for (final MapEntry(key: plist, value: zone) in {
        'plist3620006': 'p10',
        'plist3620008': 'p30',
        'plist3620009': 'p60',
        'plist9999999': 'p30',
      }.entries) {
        expect(
          WoolworthsCatalogueParser.store({
            'deliverable': true,
            'deliveryDetails': '471-$plist-true-false',
          }),
          WoolworthsStore(id: '471', priceZone: zone),
          reason: plist,
        );
      }
    });

    test('a place nobody delivers to has no store', () {
      expect(
        () => WoolworthsCatalogueParser.store(
          fixture('validate_place_undeliverable'),
        ),
        refusedAs(WoolworthsProblem.noStoreNearby),
      );
    });

    test('an answer of another shape is a changed catalogue', () {
      expect(
        () => WoolworthsCatalogueParser.store({'links': <Object?>[]}),
        refusedAs(WoolworthsProblem.catalogueChanged),
      );
    });
  });

  group('a search', () {
    test('reads each product at the store’s price', () {
      final products = WoolworthsCatalogueParser.products(
        fixture('search_milk'),
        rosebank,
      );
      expect(products, hasLength(5));
      final milk = products.first;
      expect(milk.retailer, ProductRetailer.woolworths);
      expect(milk.id, '20026875');
      expect(milk.articleCode, '20026875');
      expect(milk.storeId, '475');
      expect(milk.unitOfMeasure, 'EA');
      expect(milk.name, 'Fresh Full Cream Ayrshire Milk 2 L');
      expect(milk.brand, 'Woolies Brands');
      expect(milk.price.cents, 4799);
      expect(milk.oldPrice, isNull);
      expect(milk.isOnPromotion, isFalse);
      expect(milk.isSoldByWeight, isFalse);
      expect(
        milk.imageId,
        startsWith('Fresh-Full-Cream-Ayrshire-Milk-2-L-20026875.jpg?V=Vewa&o='),
      );
    });

    test('another price list reads another price', () {
      final products = WoolworthsCatalogueParser.products(
        fixture('search_milk'),
        const WoolworthsStore(id: '475', priceZone: 'p60'),
      );
      expect(products.first.price.cents, 3999);
    });

    test('a was-price above today’s is the old price, and a deal', () {
      final longLife = WoolworthsCatalogueParser.products(
        fixture('search_milk'),
        rosebank,
      ).singleWhere((product) => product.id == '6009171091446');
      expect(longLife.price.cents, 9999);
      expect(longLife.oldPrice?.cents, 12699);
      expect(longLife.isOnPromotion, isTrue);
      expect(longLife.packCount, 6);
    });

    test('a multi-buy is a deal with no old price', () {
      final cheese = WoolworthsCatalogueParser.products(
        fixture('search_promo'),
        rosebank,
      ).first;
      expect(cheese.isOnPromotion, isTrue);
      expect(cheese.oldPrice, isNull);
    });

    test('average-weight and variable-weight products are weighed', () {
      final products = {
        for (final product in WoolworthsCatalogueParser.products(
          fixture('browse_food'),
          rosebank,
        ))
          product.id: product,
      };
      final schnitzels = products['2034180000008']!;
      expect(schnitzels.isSoldByWeight, isTrue);
      expect(schnitzels.unitOfMeasure, 'KG');
      expect(schnitzels.price.cents, 17999);
      expect(products['2500470000008']!.isSoldByWeight, isTrue);
      expect(products['20004019']!.isSoldByWeight, isFalse);
      expect(products['20004019']!.unitOfMeasure, 'EA');
    });

    test('a product that does not read is left out', () {
      final products = WoolworthsCatalogueParser.products({
        'response': {
          'results': [
            {
              'value': 'No id',
              'data': {'p30': 10},
            },
            {
              'value': 'Letters in the id',
              'data': {'id': 'A-20011697', 'p30': 10},
            },
            {
              'value': 'No price',
              'data': {'id': '20011697'},
            },
            {
              'value': 'Half a cent',
              'data': {'id': '20011697', 'p30': 10.005},
            },
            {
              'value': '  ',
              'data': {'id': '20011697', 'p30': 10},
            },
            {
              'value': 'Fresh Full Cream Milk 2 L',
              'data': {'id': '20011697', 'p30': 40.99},
            },
          ],
        },
      }, rosebank);
      expect(products.single.name, 'Fresh Full Cream Milk 2 L');
      expect(products.single.imageId, isNull);
    });

    test('an answer with no results is a changed catalogue', () {
      expect(
        () => WoolworthsCatalogueParser.products({'response': 1}, rosebank),
        refusedAs(WoolworthsProblem.catalogueChanged),
      );
    });
  });

  group('an image', () {
    test('is kept as the file and query after Woolworths’ host only', () {
      expect(
        WoolworthsCatalogueParser.imageId(
          'https://assets.woolworthsstatic.co.za/Milk-20011697.jpg?V=Q83t&o=e&',
        ),
        'Milk-20011697.jpg?V=Q83t&o=e&',
      );
      for (final elsewhere in [
        'https://example.com/Milk.jpg',
        'http://assets.woolworthsstatic.co.za/Milk.jpg',
        'https://assets.woolworthsstatic.co.za/images/Milk.jpg',
        'https://assets.woolworthsstatic.co.za/Milk 2.jpg',
        'https://assets.woolworthsstatic.co.za/',
        'https://assets.woolworthsstatic.co.za/${'a' * 601}',
        42,
      ]) {
        expect(
          WoolworthsCatalogueParser.imageId(elsewhere),
          isNull,
          reason: '$elsewhere',
        );
      }
    });
  });

  test('a detail’s ingredients and allergens are its contents', () {
    final contents = WoolworthsCatalogueParser.contents(
      fixture('product_info'),
    );
    expect(contents.ingredientsText, "Pasteurised Cow's Milk.");
    expect(contents.allergenText, "Contains: Cow's milk.");
  });

  test('a detail that says nothing leaves the contents unknown', () {
    final contents = WoolworthsCatalogueParser.contents({
      'textualAttributes': <String, Object?>{},
      'multiAttributes': [
        {'type': 'NUTRITIONAL', 'text': 'Energy'},
      ],
    });
    expect(contents.ingredientsText, isNull);
    expect(contents.allergenText, isNull);
  });
}
