import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/photo_frames/model/frame_groceries.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';

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

  test('reads what the app writes, at either connected shop', () {
    for (final shop in [ProductRetailer.checkers, ProductRetailer.pickNPay]) {
      final groceries = FrameGroceries(shop: shop, area: CheckersArea.durban);
      expect(frameWith(groceries.toJson()).groceries, groceries);
    }
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
