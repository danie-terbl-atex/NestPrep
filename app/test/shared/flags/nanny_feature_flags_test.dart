import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

import '../../support/test_flags.dart';

/// The nanny hub's four V2 switches on the one switchboard (foundation
/// ADR-0014, nanny-hub ADR-0004 to ADR-0007): each is its own field, so
/// switching one off leaves the other three — and every other feature's —
/// where they were.
void main() {
  const nanny = [
    FeatureFlag.nannyPhotoUpdates,
    FeatureFlag.nannyPickups,
    FeatureFlag.nannyShiftOnly,
    FeatureFlag.nannyOffline,
  ];

  test('each switch is the field of its own name', () {
    expect(
      [for (final flag in nanny) flag.field],
      ['nannyPhotoUpdates', 'nannyPickups', 'nannyShiftOnly', 'nannyOffline'],
    );
    expect(
      FeatureFlag.values.map((flag) => flag.field).toSet(),
      hasLength(FeatureFlag.values.length),
    );
  });

  test('a release build shows none of them until the document says so', () {
    final release = FeatureFlags.fromFields({
      'nannyPickups': true,
    }, defaultOn: false);
    expect(release.isOn(FeatureFlag.nannyPickups), isTrue);
    for (final flag in nanny.where((f) => f != FeatureFlag.nannyPickups)) {
      expect(release.isOn(flag), isFalse, reason: flag.field);
    }
  });

  test('switching one off in a debug build leaves the rest on', () {
    final debug = FeatureFlags.fromFields({
      'nannyShiftOnly': false,
    }, defaultOn: true);
    expect(debug.isOn(FeatureFlag.nannyShiftOnly), isFalse);
    expect(debug.isOn(FeatureFlag.nannyOffline), isTrue);
    expect(debug.isOn(FeatureFlag.documentShareLinks), isTrue);
  });

  test('a field that is not a yes or no is not read as on', () {
    final flags = FeatureFlags.fromFields({
      'nannyPhotoUpdates': 'true',
    }, defaultOn: false);
    expect(flags.isOn(FeatureFlag.nannyPhotoUpdates), isFalse);
  });

  test('the tests’ switchboards mean what they say', () async {
    final on = testFlagsController(TestFlags.on);
    final off = testFlagsController(TestFlags.off);
    addTearDown(on.dispose);
    addTearDown(off.dispose);
    await pumpEventQueue();
    for (final flag in nanny) {
      expect(on.isOn(flag), isTrue, reason: flag.field);
      expect(off.isOn(flag), isFalse, reason: flag.field);
    }
  });
}
