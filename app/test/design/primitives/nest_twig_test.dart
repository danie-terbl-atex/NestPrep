import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// Twig, NestPrep's mascot (design-system ADR-0026): decoration unless
/// labelled, a box held before the art decodes, the bird alone with no tile,
/// and actions that play once and rest.
void main() {
  for (final brightness in bothThemes) {
    group('in ${brightness.name}', () {
      testWidgets('is decoration unless it is given a label', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpKit(
          tester,
          const Column(
            children: [
              NestTwig(pose: NestTwigPose.thinking),
              NestTwig(
                pose: NestTwigPose.celebrate,
                semanticsLabel: 'Planned by Twig, NestPrep’s AI',
              ),
            ],
          ),
          brightness: brightness,
        );
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Planned by Twig, NestPrep’s AI'),
          ),
          matchesSemantics(
            label: 'Planned by Twig, NestPrep’s AI',
            isImage: true,
          ),
        );
        expect(
          find.descendant(
            of: find.byType(ExcludeSemantics),
            matching: find.byType(Image),
          ),
          findsOneWidget,
        );
        semantics.dispose();
      });

      testWidgets('is the bird alone, with no tile behind him', (tester) async {
        await pumpKit(
          tester,
          const NestTwig(pose: NestTwigPose.waving),
          brightness: brightness,
        );
        expect(
          find.descendant(
            of: find.byType(NestTwig),
            matching: find.byType(DecoratedBox),
          ),
          findsNothing,
        );
      });

      testWidgets('holds its size before the art has decoded', (tester) async {
        await pumpKit(
          tester,
          const NestTwig(pose: NestTwigPose.planning, size: NestSize.twigLarge),
          brightness: brightness,
        );
        expect(
          tester.getSize(find.byType(NestTwig)),
          const Size.square(NestSize.twigLarge),
        );
      });
    });
  }

  group('acting', () {
    setUp(() => NestMotion.debugHoldStill = false);
    tearDown(() => NestMotion.debugHoldStill = true);

    Finder painterIn() => find.descendant(
      of: find.byType(NestTwig),
      matching: find.byType(CustomPaint),
    );
    Finder stillIn() => find.descendant(
      of: find.byType(NestTwig),
      matching: find.byType(Image),
    );

    /// The art decodes on the IO side, which the fake clock never reaches.
    Future<void> pumpDecoded(WidgetTester tester, Widget child) async {
      await tester.runAsync(() async {
        await pumpKit(tester, child);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
    }

    for (final action in NestTwigAction.values) {
      for (final pose in [NestTwigPose.welcome, NestTwigPose.thinking]) {
        testWidgets('${action.name} on ${pose.name} plays once, then rests on '
            'the still pose', (tester) async {
          await pumpDecoded(tester, NestTwig(pose: pose, action: action));
          expect(painterIn(), findsOneWidget);
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);

          await tester.pumpAndSettle();
          expect(painterIn(), findsNothing);
          expect(stillIn(), findsOneWidget);
          expect(
            tester.binding.hasScheduledFrame,
            isFalse,
            reason: 'a resting Twig schedules no frames (ADR-0002)',
          );
        });
      }
    }

    testWidgets('plays again each time its key changes, and only then', (
      tester,
    ) async {
      Widget twig(int key) => NestTwig(
        pose: NestTwigPose.waving,
        action: NestTwigAction.hop,
        actionKey: key,
      );
      await pumpDecoded(tester, twig(0));
      await tester.pumpAndSettle();
      expect(painterIn(), findsNothing);

      await pumpKit(tester, twig(0));
      await tester.pump();
      expect(painterIn(), findsNothing);

      await pumpKit(tester, twig(1));
      await tester.pump();
      expect(painterIn(), findsOneWidget);
      await tester.pumpAndSettle();
      expect(stillIn(), findsOneWidget);
    });

    testWidgets('under reduce motion he is the still pose and nothing moves', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await pumpKit(
          tester,
          const NestTwig(
            pose: NestTwigPose.welcome,
            action: NestTwigAction.wave,
          ),
          reduceMotion: true,
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      expect(painterIn(), findsNothing);
      expect(stillIn(), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('while his route is covered he shows the still pose', (
      tester,
    ) async {
      await pumpDecoded(
        tester,
        const TickerMode(
          enabled: false,
          child: NestTwig(
            pose: NestTwigPose.waving,
            action: NestTwigAction.arrive,
          ),
        ),
      );
      expect(painterIn(), findsNothing);
      expect(stillIn(), findsOneWidget);
    });

    testWidgets('in the widget suite he holds still, so pictures settle', (
      tester,
    ) async {
      NestMotion.debugHoldStill = true;
      await pumpKit(
        tester,
        const NestTwig(pose: NestTwigPose.welcome, action: NestTwigAction.wave),
      );
      await tester.pump();
      expect(painterIn(), findsNothing);
    });
  });

  group('the art (FE-18)', () {
    /// Width, height and PNG colour type from the IHDR chunk.
    (int, int, int) header(String path) {
      final bytes = ByteData.sublistView(File(path).readAsBytesSync());
      return (bytes.getUint32(16), bytes.getUint32(20), bytes.getUint8(25));
    }

    /// Canvas width and height from a lossy-with-alpha WebP's VP8X chunk.
    (int, int) webpSize(String path) {
      final bytes = File(path).readAsBytesSync();
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
      expect(String.fromCharCodes(bytes.sublist(12, 16)), 'VP8X');
      int read24(int at) =>
          bytes[at] | bytes[at + 1] << 8 | bytes[at + 2] << 16;
      return (read24(24) + 1, read24(27) + 1);
    }

    test('every rigged layer is the rig canvas, with alpha, and the whole rig '
        'stays small (design-system ADR-0026)', () {
      final layers = [for (final pose in NestTwigPose.values) ...pose.rig];
      expect(layers, isNotEmpty);
      var bytes = 0;
      for (final layer in layers) {
        expect(webpSize(layer.asset), (
          NestTwigRig.rasterSize,
          NestTwigRig.rasterSize,
        ));
        bytes += File(layer.asset).lengthSync();
      }
      expect(bytes, lessThan(120 * 1024));
    });

    test('a rig has one body, and only its moving parts turn', () {
      for (final pose in NestTwigPose.values.where((p) => p.rig.isNotEmpty)) {
        expect(
          pose.rig.where((layer) => layer.part == NestTwigPart.body),
          hasLength(1),
        );
        for (final layer in pose.rig) {
          expect(layer.pivot.dx, inInclusiveRange(0, 1));
          expect(layer.pivot.dy, inInclusiveRange(0, 1));
        }
      }
    });

    for (final pose in NestTwigPose.values) {
      test('${pose.name} is a transparent square, sharp at the largest Twig '
          'on a 4× screen and no bigger than that', () {
        final (width, height, colourType) = header(pose.asset);
        expect(width, height);
        // 6 is truecolour with alpha.
        expect(colourType, 6);
        const largest = NestSize.twigLarge * 4;
        expect(width, greaterThanOrEqualTo(largest));
        expect(width, lessThanOrEqualTo(NestTwigPose.rasterSize));
      });
    }
  });
}
