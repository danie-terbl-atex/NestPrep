import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_store.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/photo_frames/model/frame_groceries.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

void main() {
  PhotoFrame frameWith(Object? groceries, {bool present = true}) =>
      PhotoFrame.fromJson({
        'id': 'f1',
        'name': 'Kitchen frame',
        if (present) 'groceries': groceries,
      });

  test('a frame without the field has it off', () {
    expect(frameWith(null, present: false).groceries, isNull);
    expect(frameWith(null).groceries, isNull);
  });

  const store = WoolworthsStore(id: '2008', priceZone: 'p30');
  const woolworths = FrameGroceries(
    shop: ProductRetailer.woolworths,
    area: CheckersArea.durban,
    store: store,
  );

  test('reads what the app writes, at every connected shop', () {
    for (final shop in [ProductRetailer.checkers, ProductRetailer.pickNPay]) {
      final groceries = FrameGroceries(shop: shop, area: CheckersArea.durban);
      expect(frameWith(groceries.toJson()).groceries, groceries);
    }
    expect(frameWith(woolworths.toJson()).groceries, woolworths);
  });

  test('writes the store and price list at Woolworths, and only there', () {
    expect(woolworths.toJson(), {
      'shop': 'woolworths',
      'area': 'durban',
      'store': '2008',
      'priceZone': 'p30',
    });
    expect(woolworths.copyWith(shop: ProductRetailer.pickNPay).toJson(), {
      'shop': 'pickNPay',
      'area': 'durban',
    });
  });

  group('what is saved', () {
    test('at Woolworths, the store found for the area now', () async {
      final asked = <Object>[];
      final located = await woolworths
          .copyWith(area: CheckersArea.pretoria)
          .located((near) async {
            asked.add(near);
            return const WoolworthsStore(id: '31', priceZone: 'p10');
          });
      expect(asked, [CheckersArea.pretoria.centre]);
      expect(located.store, const WoolworthsStore(id: '31', priceZone: 'p10'));
    });

    test('anywhere else, no store, and nothing is asked', () async {
      final located = await woolworths
          .copyWith(shop: ProductRetailer.checkers)
          .located((_) => fail('looked a store up'));
      expect(
        located,
        const FrameGroceries(
          shop: ProductRetailer.checkers,
          area: CheckersArea.durban,
        ),
      );
    });

    test('never a store the rules would refuse', () async {
      for (final found in const [
        WoolworthsStore(id: '12345678901', priceZone: 'p30'),
        WoolworthsStore(id: '2008', priceZone: 'p20'),
      ]) {
        await expectLater(
          woolworths.located((_) async => found),
          throwsA(
            isA<WoolworthsFailure>().having(
              (failure) => failure.problem,
              'problem',
              WoolworthsProblem.catalogueChanged,
            ),
          ),
        );
      }
    });
  });

  test('writes the exact shape the rules ask for', () {
    expect(
      const FrameGroceries(
        shop: ProductRetailer.checkers,
        area: CheckersArea.capeTown,
      ).toJson(),
      {'shop': 'checkers', 'area': 'capeTown'},
    );
  });

  group('junk is off, never a crash', () {
    for (final junk in <Object?>[
      'checkers',
      42,
      <Object?>['checkers', 'capeTown'],
      {'shop': 'woolworths', 'area': 'capeTown'},
      {'shop': 'woolworths', 'area': 'capeTown', 'store': '2008'},
      {
        'shop': 'woolworths',
        'area': 'capeTown',
        'store': 2008,
        'priceZone': 'p30',
      },
      {
        'shop': 'woolworths',
        'area': 'capeTown',
        'store': '',
        'priceZone': 'p30',
      },
      {
        'shop': 'woolworths',
        'area': 'capeTown',
        'store': '2008',
        'priceZone': 'p20',
      },
      {
        'shop': 'woolworths',
        'area': 'london',
        'store': '2008',
        'priceZone': 'p30',
      },
      {'shop': 'spar', 'area': 'capeTown'},
      {'shop': 'checkers', 'area': 'london'},
      {'shop': 'checkers'},
      {'area': 'capeTown'},
      {'shop': 1, 'area': 'capeTown'},
      {'shop': 'checkers', 'area': true},
      {'shop': 'Checkers', 'area': 'capeTown'},
    ]) {
      test('$junk', () {
        expect(frameWith(junk).groceries, isNull);
      });
    }
  });

  test('a frame with junk groceries still reads the rest of itself', () {
    final frame = frameWith({'shop': 'spar'});
    expect(frame.name, 'Kitchen frame');
    expect(frame.groceries, isNull);
  });
}
