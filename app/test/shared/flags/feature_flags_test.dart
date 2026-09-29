import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

/// The one switchboard (foundation ADR-0014): a V2 capability is on in a
/// debug build and off in a release one until `appConfig/flags` says, and an
/// explicit value wins in both.
void main() {
  test('an unmentioned flag is on in debug and off in release', () {
    const debug = FeatureFlags.defaults(isDebugBuild: true);
    const release = FeatureFlags.defaults(isDebugBuild: false);
    for (final flag in FeatureFlag.values) {
      expect(debug.isOn(flag), isTrue, reason: flag.key);
      expect(release.isOn(flag), isFalse, reason: flag.key);
    }
  });

  test('the document wins in both, and only a bool counts', () {
    final release = FeatureFlags.fromDocument({
      'snapSchoolLetter': true,
      'mentalLoadView': 'yes',
    }, isDebugBuild: false);
    expect(release.isOn(FeatureFlag.snapSchoolLetter), isTrue);
    expect(release.isOn(FeatureFlag.mentalLoadView), isFalse);

    final debug = FeatureFlags.fromDocument({
      'mentalLoadView': false,
    }, isDebugBuild: true);
    expect(debug.isOn(FeatureFlag.mentalLoadView), isFalse);
  });

  test('no document is the defaults, and equal flags are equal', () {
    expect(
      FeatureFlags.fromDocument(null, isDebugBuild: false),
      const FeatureFlags.defaults(isDebugBuild: false),
    );
    expect(
      FeatureFlags.everythingOff.isOn(FeatureFlag.snapSchoolLetter),
      isFalse,
    );
    expect(FeatureFlags.everythingOn.isOn(FeatureFlag.mentalLoadView), isTrue);
  });
}
