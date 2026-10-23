import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/welcome_tour/model/callout_placement.dart';

/// Where a callout goes (welcome-tour ADR-0002): the side with more room,
/// inside the safe area, never wider than a card, pointing at the target.
void main() {
  // A 360 × 800 phone with a 24-point status bar and a 48-point gesture strip.
  const safe = Rect.fromLTRB(0, 24, 360, 752);

  test('below a target near the top', () {
    final placement = CalloutPlacement.of(
      target: const Rect.fromLTWH(20, 80, 100, 40),
      safe: safe,
    );
    expect(placement.side, CalloutSide.below);
    expect(placement.edge, 120 + 12);
    expect(placement.maxHeight, 752 - 132);
  });

  test('above a target near the bottom, clear of the gesture strip', () {
    final placement = CalloutPlacement.of(
      target: const Rect.fromLTWH(20, 680, 320, 60),
      safe: safe,
    );
    expect(placement.side, CalloutSide.above);
    expect(placement.edge, 680 - 12);
    expect(placement.maxHeight, 668 - 24);
  });

  test(
    'inside the gutters on a small phone, at most a card wide on a big one',
    () {
      final small = CalloutPlacement.of(
        target: const Rect.fromLTWH(300, 80, 40, 40),
        safe: safe,
      );
      expect(small.width, 360 - 32);
      expect(small.left, 16);
      final big = CalloutPlacement.of(
        target: const Rect.fromLTWH(900, 80, 40, 40),
        safe: const Rect.fromLTWH(0, 0, 1200, 800),
      );
      expect(big.width, 420);
      expect(big.left + big.width, lessThanOrEqualTo(1200 - 16));
    },
  );

  test('its pointer sits under the target, kept off the card’s corners', () {
    final middle = CalloutPlacement.of(
      target: const Rect.fromLTWH(160, 80, 40, 40),
      safe: safe,
    );
    expect(middle.left + middle.pointerX, 180);
    final corner = CalloutPlacement.of(
      target: const Rect.fromLTWH(340, 80, 20, 20),
      safe: safe,
    );
    expect(corner.pointerX, lessThanOrEqualTo(corner.width - 28));
  });

  test('a target taller than the room either side gets the card over it, '
      'at the foot of the safe area', () {
    final placement = CalloutPlacement.of(
      target: const Rect.fromLTRB(16, 100, 344, 700),
      safe: safe,
    );
    expect(placement.side, CalloutSide.over);
    expect(placement.edge, 752 - 16);
    expect(placement.maxHeight, lessThanOrEqualTo(safe.height / 2));
  });

  test('a target partly off the screen points at the part on it', () {
    final placement = CalloutPlacement.of(
      target: const Rect.fromLTWH(-100, 80, 200, 40),
      safe: safe,
    );
    expect(placement.left + placement.pointerX, closeTo(50, 0.01));
  });
}
