import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';

import '../../support/fake_feature_flag_source.dart';

/// The V2 switches (foundation ADR-0014): the document wins when it says
/// anything; otherwise on in debug, off in release; and a read that fails
/// never flips a switch.
void main() {
  group('FeatureFlags', () {
    test('a field the document sets wins, either way', () {
      final flags = FeatureFlags.fromFields({
        'documentShareLinks': false,
        'documentOfflineCopies': true,
      }, defaultOn: true);
      expect(flags.isOn(FeatureFlag.documentShareLinks), isFalse);
      expect(flags.isOn(FeatureFlag.documentOfflineCopies), isTrue);

      final release = FeatureFlags.fromFields({
        'documentOfflineCopies': true,
      }, defaultOn: false);
      expect(release.isOn(FeatureFlag.documentOfflineCopies), isTrue);
    });

    test('a field it does not set is the build default — on in debug, off in '
        'release', () {
      expect(
        const FeatureFlags.defaults(defaultOn: true)
            .isOn(FeatureFlag.documentShareLinks),
        isTrue,
      );
      expect(
        FeatureFlags.fromFields(
          const {},
          defaultOn: false,
        ).isOn(FeatureFlag.documentShareLinks),
        isFalse,
      );
    });

    test('a value that is not a boolean is as if it were absent', () {
      final flags = FeatureFlags.fromFields({
        'documentShareLinks': 'yes',
        'documentOfflineCopies': 1,
      }, defaultOn: false);
      expect(flags.isOn(FeatureFlag.documentShareLinks), isFalse);
      expect(flags.isOn(FeatureFlag.documentOfflineCopies), isFalse);
    });

    test('every flag names the field that switches it', () {
      expect(FeatureFlag.values.map((flag) => flag.field).toSet(), {
        'documentShareLinks',
        'documentOfflineCopies',
        'referralRewards',
      });
    });
  });

  group('FeatureFlagsController', () {
    late FakeFeatureFlagSource source;

    setUp(() => source = FakeFeatureFlagSource());
    tearDown(() => source.close());

    test('starts at the build default, before the document answers', () {
      final release = FeatureFlagsController(source: source, defaultOn: false);
      addTearDown(release.dispose);
      expect(release.isOn(FeatureFlag.documentShareLinks), isFalse);
      expect(source.lastDefault, isFalse);
    });

    test('follows the document live, and tells whoever listens', () async {
      final controller = FeatureFlagsController(source: source);
      addTearDown(controller.dispose);
      var told = 0;
      controller.addListener(() => told++);

      source.emit({'documentShareLinks': false});
      await Future<void>.delayed(Duration.zero);

      expect(controller.isOn(FeatureFlag.documentShareLinks), isFalse);
      expect(controller.isOn(FeatureFlag.documentOfflineCopies), isTrue);
      expect(told, 1);
      expect(controller.hasAnswered, isTrue);
    });

    test('an unreadable document leaves the defaults standing', () async {
      final controller = FeatureFlagsController(
        source: source,
        defaultOn: false,
      );
      addTearDown(controller.dispose);

      source.fail(StateError('offline'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.isOn(FeatureFlag.documentShareLinks), isFalse);
      expect(controller.hasAnswered, isFalse);
    });
  });
}
