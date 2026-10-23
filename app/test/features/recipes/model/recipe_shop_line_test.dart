import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/model/recipe_shop_line.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_checkers.dart';

/// One ingredient as *Add to grocer* found it (recipes ADR-0005): the
/// product chosen is one a cart can take, Jev's best when he named one.
void main() {
  const line = RecipeShopLine(index: 2, name: 'Onions', quantity: '2');

  test('chooses the first product a cart can take', () {
    final found = line.found([
      checkersProduct('Onions loose', id: 'w', unitOfMeasure: 'KG'),
      checkersProduct('Onions 1kg', id: 'gone', isInStock: false),
      checkersProduct('Onions 2kg', id: 'ok'),
    ]);

    expect(found.search, RecipeShopSearch.found);
    expect(found.chosen?.id, 'ok');
    expect(found.isBestMatch, isFalse);
    expect(found.products, hasLength(3), reason: 'all kept to swap between');
  });

  test('prefers Jev’s best when it can be bought', () {
    final found = line.found([
      checkersProduct('Onion rings', id: 'a'),
      checkersProduct('Onions 1kg', id: 'b'),
    ], best: 'b');

    expect(found.chosen?.id, 'b');
    expect(found.isBestMatch, isTrue);
  });

  test('nothing buyable is not found, and still goes on the list', () {
    final found = line.found([
      checkersProduct('Onions loose', unitOfMeasure: 'KG'),
    ]);

    expect(found.search, RecipeShopSearch.notFound);
    expect(found.chosen, isNull);
    expect(found.isIncluded, isTrue);
  });

  test('a failed search keeps the line, by name', () {
    final failed = line.failedWith(const UnavailableFailure());

    expect(failed.isSettled, isTrue);
    expect(failed.chosen, isNull);
    expect(failed.failure, isA<UnavailableFailure>());
  });

  test('toggling and choosing keep everything else', () {
    final found = line.found([
      checkersProduct('Onions 1kg', id: 'a'),
      checkersProduct('Onions 2kg', id: 'b'),
    ]);
    final off = found.toggled();
    final swapped = off.choosing(found.products.last);

    expect(off.isIncluded, isFalse);
    expect(off.chosen?.id, 'a');
    expect(swapped.chosen?.id, 'b');
    expect(swapped.isIncluded, isFalse);
    expect(swapped.products, hasLength(2));
  });
}
