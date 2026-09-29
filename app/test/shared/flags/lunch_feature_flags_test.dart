import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

import '../../support/test_flags.dart';

/// Lunch-box's three V2 switches on the one switchboard (foundation
/// ADR-0014, lunch-box ADR-0006 to ADR-0008): each its own field, dark in a
/// release build until the document says so, and switched off alone.
void main() {
  const lunch = [
    FeatureFlag.lunchPantry,
    FeatureFlag.lunchBudget,
    FeatureFlag.lunchKidPicks,
  ];

  test('each switch is the field of its own name', () {
    expect(
      [for (final flag in lunch) flag.field],
      ['lunchPantry', 'lunchBudget', 'lunchKidPicks'],
    );
    expect(
      FeatureFlag.values.map((flag) => flag.field).toSet(),
      hasLength(FeatureFlag.values.length),
    );
  });

  test('a release build shows none of them until the document says so', () {
    final release = FeatureFlags.fromFields({
      'lunchBudget': true,
    }, defaultOn: false);
    expect(release.isOn(FeatureFlag.lunchBudget), isTrue);
    expect(release.isOn(FeatureFlag.lunchPantry), isFalse);
    expect(release.isOn(FeatureFlag.lunchKidPicks), isFalse);
  });

  test('switching one off in a debug build leaves the rest on', () {
    final debug = FeatureFlags.fromFields({
      'lunchKidPicks': false,
    }, defaultOn: true);
    expect(debug.isOn(FeatureFlag.lunchKidPicks), isFalse);
    expect(debug.isOn(FeatureFlag.lunchPantry), isTrue);
  });

  test('the tests’ switchboards mean what they say', () async {
    final on = testFlagsController(TestFlags.on);
    final off = testFlagsController(TestFlags.off);
    addTearDown(on.dispose);
    addTearDown(off.dispose);
    await pumpEventQueue();
    for (final flag in lunch) {
      expect(on.isOn(flag), isTrue, reason: flag.field);
      expect(off.isOn(flag), isFalse, reason: flag.field);
    }
  });
}
