import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_checkers/state/product_match_controller.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/household_fixtures.dart';

GroceryItem item(String name, {String id = 'i1'}) =>
    GroceryItem(id: id, name: name, addedBy: Fixtures.samMemberId);

const debounce = Duration(milliseconds: 40);

/// Real time, a little past the debounce, then every answer after it.
Future<void> settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 60));
  await pumpEventQueue();
}

final class Harness {
  Harness() {
    addTearDown(controller.dispose);
  }

  final catalogue = FakeCheckersCatalogue()
    ..products = [checkersProduct('Clover Fresh Full Cream Milk 2L')];
  final areas = FakeCheckersAreaPreference();
  final location = FakeLocationSource();
  final groceries = FakeGroceryRepository();

  late final controller = ProductMatchController(
    catalogue: catalogue,
    placeResolver: CheckersPlaceResolver(
      locationSource: location,
      areaPreference: areas,
    ),
    groceryRepository: groceries,
    householdId: Fixtures.householdId,
    memberId: Fixtures.samMemberId,
    debounce: debounce,
  );
}

void main() {
  test(
    'nothing is searched until an item asks, then after the debounce',
    () async {
      final h = Harness();
      await pumpEventQueue();
      expect(h.catalogue.searches, isEmpty);

      h.controller.lookFor(item('milk'));
      expect(h.controller.matches, isA<AsyncLoading<Object>>());
      await pumpEventQueue();
      expect(h.catalogue.searches, isEmpty);

      await settle();
      expect(h.catalogue.searches.single.query, 'milk');
      expect(h.controller.matches, isA<AsyncData<Object>>());
    },
  );

  test('items added quickly in a row search only for the last one', () async {
    final h = Harness();
    h.controller
      ..lookFor(item('milk'))
      ..lookFor(item('bread', id: 'i2'));
    await settle();
    expect(
      [for (final search in h.catalogue.searches) search.query],
      ['bread'],
    );
    expect(h.controller.target?.itemId, 'i2');
  });

  test('nothing close is an empty answer, not a failure', () async {
    final h = Harness()..catalogue.products = const [];
    h.controller.lookFor(item('unobtainium'));
    await settle();
    expect(
      h.controller.matches,
      isA<AsyncData<List<Object>>>().having((d) => d.value, 'value', isEmpty),
    );
  });

  test('a failure is kept for the panel, and retry searches again', () async {
    final h = Harness()
      ..catalogue.failWith = const CheckersFailure(
        CheckersProblem.catalogueBusy,
      );
    h.controller.lookFor(item('milk'));
    await settle();
    expect(h.controller.matches, isA<AsyncFailure<Object>>());

    h.catalogue.failWith = null;
    h.controller.retry();
    await settle();
    expect(h.catalogue.searches, hasLength(2));
    expect(h.controller.matches, isA<AsyncData<Object>>());
  });

  test('an answer for a panel somebody closed is dropped', () async {
    final h = Harness()..catalogue.gate = Completer<void>();
    h.controller.lookFor(item('milk'));
    await settle();
    h.controller.dismiss();
    h.catalogue.gate!.complete();
    await pumpEventQueue();
    expect(h.controller.target, isNull);
    expect(h.controller.matches, isA<AsyncLoading<Object>>());
  });

  test(
    'picking stores the product on the item as the picker, and closes',
    () async {
      final h = Harness();
      h.controller.lookFor(item('milk'));
      await settle();
      await h.controller.pick(h.catalogue.products.single);

      final written = h.groceries.matchesSet.single;
      expect(written.itemId, 'i1');
      expect(written.match.retailer, ProductRetailer.checkers);
      expect(written.match.productId, '5d3af63bf434cf8420737dd6');
      expect(written.match.articleCode, '10136729EA');
      expect(written.match.price.cents, 3799);
      expect(written.match.pickedBy, Fixtures.samMemberId);
      expect(h.controller.target, isNull);
    },
  );

  test('a refused pick keeps the panel open and says why', () async {
    final h = Harness()
      ..groceries.failWritesWith = const PermissionDeniedFailure();
    h.controller.lookFor(item('milk'));
    await settle();
    await h.controller.pick(h.catalogue.products.single);
    expect(h.controller.target?.itemId, 'i1');
    expect(h.controller.actionFailure, isA<PermissionDeniedFailure>());
  });

  test('clearing takes the pick off the item', () async {
    final h = Harness();
    await h.controller.clear(item('milk'));
    expect(h.groceries.matchesCleared, ['i1']);
  });

  group('where the search looks', () {
    test(
      'Cape Town, when nothing is chosen and location is not allowed',
      () async {
        final h = Harness();
        h.controller.lookFor(item('milk'));
        await settle();
        expect(h.catalogue.searches.single.near, CheckersArea.capeTown.centre);
        expect(h.controller.place?.area, CheckersArea.capeTown);
      },
    );

    test('the phone, when its owner already allowed location', () async {
      const here = Coordinates(latitude: -26.1, longitude: 28);
      final h = Harness()..location.alreadyAllowedAt = here;
      h.controller.lookFor(item('milk'));
      await settle();
      expect(h.catalogue.searches.single.near, here);
      expect(h.controller.place?.isDevice, isTrue);
      // Never asked: the grocery screen is not where a prompt belongs.
      expect(h.location.consentsAsked, 0);
    });

    test('a chosen area is remembered and searched at once', () async {
      final h = Harness();
      h.controller.lookFor(item('milk'));
      await settle();
      await h.controller.chooseArea(CheckersArea.durban);
      await settle();
      expect(h.areas.chosen[Fixtures.householdId], CheckersArea.durban);
      expect(h.catalogue.searches.last.near, CheckersArea.durban.centre);
      expect(h.controller.place?.area, CheckersArea.durban);
    });
  });
}
