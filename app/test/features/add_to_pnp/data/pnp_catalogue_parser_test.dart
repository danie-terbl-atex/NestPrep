import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_image_url.dart';
import 'package:nestprep/features/add_to_pnp/data/pnp_catalogue_parser.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

Object? fixture(String name) => jsonDecode(
  File('test/features/add_to_pnp/fixtures/$name.json').readAsStringSync(),
);

/// Pick n Pay's answers, cut from the 2026-10-12 captures, read at the edge
/// (`ENG-09`, add-to-pnp ADR-0002).
void main() {
  final products = PnpCatalogueParser.products(fixture('search_mixed'), 'GC13');
  final byCode = {for (final product in products) product.id: product};

  test('every product reads, at the store it was asked at', () {
    expect(products, hasLength(6));
    expect(
      products.every((p) => p.retailer == ProductRetailer.pickNPay),
      isTrue,
    );
    expect(products.every((p) => p.storeId == 'GC13'), isTrue);
  });

  test('the code splits into the stored article digits and unit', () {
    final cheddars = byCode['000000000000539078_EA']!;
    expect(cheddars.name, 'Bakers Fruit Chutney Mini Cheddars 6 x 33g');
    expect(cheddars.articleCode, '000000000000539078');
    expect(cheddars.unitOfMeasure, 'EA');
    expect(cheddars.price.cents, 4899);
    expect(cheddars.packCount, 6);
    expect(cheddars.isInStock, isTrue);
    expect(cheddars.isSoldByWeight, isFalse);
    expect(cheddars.hasContentsText, isFalse, reason: 'search carries none');
  });

  test('the picture is a path on PnP’s own CDN, joined back to it', () {
    final image = byCode['000000000000539078_EA']!.imageId!;
    expect(image, startsWith('sys-master/images/'));
    expect(image, endsWith('300Wx300H'), reason: 'the carousel size');
    final url = retailerImageUrl(ProductRetailer.pickNPay, image)!;
    expect(url.host, pnpImageHost);
    expect(url.scheme, 'https');
  });

  test('a deal is a promotion even when the price is not reduced', () {
    final chews = byCode['000000000000210944_EA']!;
    expect(chews.isOnPromotion, isTrue);
    expect(chews.oldPrice, isNull);
  });

  test('out of stock says so', () {
    expect(byCode['000000000000347577_EA']!.isInStock, isFalse);
  });

  test('grams and average weights are sold by weight, a struck price kept', () {
    final steak = byCode['000000000000263689_KGM']!;
    expect(steak.isSoldByWeight, isTrue);
    expect(steak.unitOfMeasure, 'KGM');
    expect(steak.oldPrice?.cents, 14999);
    expect(steak.isOnPromotion, isTrue);
    final porterhouse = byCode['000000000000741260_EA']!;
    expect(porterhouse.isSoldByWeight, isTrue, reason: 'AVERAGE_WEIGHT');
  });

  test(
    'an empty category is empty, and a page with no products is changed',
    () {
      expect(
        PnpCatalogueParser.products(fixture('search_empty'), 'GC13'),
        isEmpty,
      );
      expect(
        () =>
            PnpCatalogueParser.products(const {'errors': <Object?>[]}, 'GC13'),
        throwsA(
          isA<PnpFailure>().having(
            (failure) => failure.problem,
            'problem',
            PnpProblem.catalogueChanged,
          ),
        ),
      );
    },
  );

  test('a product of another shape is left out, not guessed at', () {
    final read = PnpCatalogueParser.products(const {
      'products': [
        {
          'code': 'not-a-code',
          'name': 'X',
          'price': {'value': 1},
        },
        {
          'code': '000000000000000001_EA',
          'name': 'X',
          'price': {'value': 1.234},
        },
      ],
    }, 'GC13');
    expect(read, isEmpty);
  });

  test(
    'a detail’s allergens, warnings and ingredients become its contents',
    () {
      final contents = PnpCatalogueParser.contents(
        fixture('detail_with_contents'),
      );
      expect(
        contents.allergenText,
        'Gluten. May contain soya. Contains barley.',
      );
      expect(contents.ingredientsText, startsWith('Potatoes, Vegetable Oil'));
    },
  );

  test('a detail that says nothing leaves the contents unknown', () {
    final contents = PnpCatalogueParser.contents(
      fixture('detail_without_contents'),
    );
    expect(contents.allergenText, isNull);
    expect(contents.ingredientsText, isNull);
  });

  test('a cart names its store and its guid', () {
    const cart = {
      'guid': 'a-guid',
      'baseStore': {'uid': 'GC13', 'name': 'GC13 Benmore'},
    };
    expect(PnpCatalogueParser.storeCode(cart), 'GC13');
    expect(PnpCatalogueParser.cartGuid(cart), 'a-guid');
    expect(PnpCatalogueParser.storeCode(const {}), isNull);
  });
}
