import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:provider/provider.dart';

/// The one typed source of V2 switches (verdict 003, household ADR-0004): on
/// in a debug build, off in a release, and whatever the stored document says
/// once it says something readable.
void main() {
  group('the defaults', () {
    test('are on in a debug build and off in a release', () {
      expect(FeatureFlags.defaults().coParenting, isTrue);
      expect(FeatureFlags.defaults(isDebug: false).coParenting, isFalse);
    });
  });

  group('the stored document', () {
    test('turns a flag on or off in either build', () {
      expect(
        FeatureFlags.fromStored({
          'coParenting': true,
        }, isDebug: false).coParenting,
        isTrue,
      );
      expect(
        FeatureFlags.fromStored({'coParenting': false}).coParenting,
        isFalse,
      );
    });

    test('says nothing readable, and the default stands', () {
      for (final stored in <Map<String, Object?>?>[
        null,
        {},
        {'coParenting': 'yes'},
        {'coParenting': 1},
      ]) {
        expect(
          FeatureFlags.fromStored(stored, isDebug: false).coParenting,
          isFalse,
          reason: '$stored',
        );
        expect(
          FeatureFlags.fromStored(stored).coParenting,
          isTrue,
          reason: '$stored',
        );
      }
    });

    test('keeps the key the console writes', () {
      expect(FeatureFlags.coParentingKey, 'coParenting');
    });
  });

  group('where a widget reads them', () {
    Future<FeatureFlags> readIn(
      WidgetTester tester, {
      FeatureFlags? provided,
    }) async {
      late FeatureFlags read;
      final probe = Builder(
        builder: (context) {
          read = FeatureFlags.of(context);
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(
        provided == null
            ? probe
            : Provider<FeatureFlags>.value(value: provided, child: probe),
      );
      return read;
    }

    testWidgets('the provided flags win', (tester) async {
      const off = FeatureFlags(coParenting: false);
      expect(await readIn(tester, provided: off), off);
    });

    testWidgets('with nothing provided, the build’s defaults', (tester) async {
      expect(await readIn(tester), FeatureFlags.defaults());
    });
  });

  test('two sets with the same switches are equal', () {
    expect(
      const FeatureFlags(coParenting: true),
      const FeatureFlags(coParenting: true),
    );
    expect(
      const FeatureFlags(coParenting: true).hashCode,
      const FeatureFlags(coParenting: true).hashCode,
    );
  });
}
