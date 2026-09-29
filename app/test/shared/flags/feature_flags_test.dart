import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

/// The one switchboard (foundation ADR-0014): a V2 capability is on in a
/// debug build and off in a release one until `appConfig/flags` says, and an
/// explicit value wins in both.
void main() {
  test('an unmentioned flag is on in debug and off in release', () {
    for (final flag in FeatureFlag.values) {
      expect(FeatureFlags.everythingOn.isOn(flag), isTrue, reason: flag.field);
      expect(
        FeatureFlags.everythingOff.isOn(flag),
        isFalse,
        reason: flag.field,
      );
    }
  });

  test('the document wins in both, and only a bool counts', () {
    final release = FeatureFlags.fromFields({
      'snapSchoolLetter': true,
      'mentalLoadView': 'yes',
    }, defaultOn: false);
    expect(release.isOn(FeatureFlag.snapSchoolLetter), isTrue);
    expect(release.isOn(FeatureFlag.mentalLoadView), isFalse);

    final debug = FeatureFlags.fromFields({
      'mentalLoadView': false,
    }, defaultOn: true);
    expect(debug.isOn(FeatureFlag.mentalLoadView), isFalse);
  });

  test('no document is the defaults, and equal flags are equal', () {
    expect(
      FeatureFlags.fromFields(const {}, defaultOn: false),
      FeatureFlags.everythingOff,
    );
  });
}
