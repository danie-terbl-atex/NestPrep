import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// Twig, the AI mascot (design-system ADR-0012): decoration unless labelled,
/// a box held before the art decodes, and a tile that keeps the art's dark
/// outline legible in both themes.
void main() {
  /// The art's outline, measured from the five poses on 2026-10-07: the most
  /// common colour among their dark pixels. It is in the pictures, not in the
  /// app's palette, so it is written down here rather than as a token.
  const outline = Color(0xFF402000);

  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (la > lb ? la + 0.05 : lb + 0.05) /
        (la > lb ? lb + 0.05 : la + 0.05);
  }

  Color tileOf(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(NestTwig),
        matching: find.byType(DecoratedBox),
      ),
    );
    return (box.decoration as BoxDecoration).color!;
  }

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

      testWidgets('sits on a light tile its outline can be seen on, whatever '
          'the canvas', (tester) async {
        await pumpKit(
          tester,
          const NestTwig(pose: NestTwigPose.waving),
          brightness: brightness,
        );
        // WCAG 1.4.11: a graphic needed to understand it holds 3:1.
        expect(contrast(outline, tileOf(tester)), greaterThanOrEqualTo(3));
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

  group('the art (FE-18)', () {
    /// Width, height and PNG colour type from the IHDR chunk.
    (int, int, int) header(String path) {
      final bytes = ByteData.sublistView(File(path).readAsBytesSync());
      return (bytes.getUint32(16), bytes.getUint32(20), bytes.getUint8(25));
    }

    for (final pose in NestTwigPose.values) {
      test('${pose.name} is a transparent square, sharp at the largest Twig '
          'on a 4× screen and no bigger than that', () {
        final (width, height, colourType) = header(pose.asset);
        expect(width, height);
        // 6 is truecolour with alpha.
        expect(colourType, 6);
        const largest = NestSize.twigLarge * NestTwig.artShare * 4;
        expect(width, greaterThanOrEqualTo(largest));
        expect(width, lessThanOrEqualTo(NestTwigPose.rasterSize));
      });
    }
  });
}
