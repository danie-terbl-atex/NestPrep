import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../support/pump_kit.dart';

/// The brand in the kit (design-system ADR-0003): the nest and the wordmark
/// cut from the logo, and the empty state that can show the nest.
void main() {
  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('the wordmark is the name, read once, as a heading', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpKit(
          tester,
          const NestWordmark(semanticsLabel: AppCopy.appName),
          brightness: brightness,
        );
        expect(
          tester.getSemantics(find.byType(NestWordmark)),
          matchesSemantics(label: AppCopy.appName, isHeader: true),
        );
        semantics.dispose();
      });

      testWidgets('the wordmark takes the theme accent, not its own green', (
        tester,
      ) async {
        await pumpKit(
          tester,
          const NestWordmark(semanticsLabel: AppCopy.appName),
          brightness: brightness,
        );
        final accent = brightness == Brightness.dark
            ? NestColors.dark.accent
            : NestColors.light.accent;
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.color, accent);
        expect(image.colorBlendMode, BlendMode.srcIn);
      });

      testWidgets('both hold their final size before the image decodes', (
        tester,
      ) async {
        await pumpKit(
          tester,
          const Column(
            children: [
              NestBrandMark(width: NestSize.brandMarkLarge),
              NestWordmark(
                semanticsLabel: AppCopy.appName,
                height: NestSize.wordmarkSmall,
              ),
            ],
          ),
          brightness: brightness,
        );
        final mark = tester.getSize(find.byType(NestBrandMark));
        expect(mark.width, NestSize.brandMarkLarge);
        expect(
          mark.height,
          closeTo(NestSize.brandMarkLarge / NestBrandAssets.markAspect, 0.01),
        );
        final word = tester.getSize(find.byType(NestWordmark));
        expect(word.height, NestSize.wordmarkSmall);
        expect(
          word.width,
          closeTo(
            NestSize.wordmarkSmall * NestBrandAssets.wordmarkAspect,
            0.01,
          ),
        );
      });

      testWidgets('the nest is decoration unless it is given a label', (
        tester,
      ) async {
        await pumpKit(
          tester,
          const Column(
            children: [
              NestBrandMark(),
              NestBrandMark(semanticsLabel: AppCopy.appName),
            ],
          ),
          brightness: brightness,
        );
        expect(find.bySemanticsLabel(AppCopy.appName), findsOneWidget);
      });

      testWidgets('an empty state without an icon shows the nest', (
        tester,
      ) async {
        await pumpKit(
          tester,
          const NestEmptyView(title: 'Nothing yet', message: 'Add the first.'),
          brightness: brightness,
        );
        expect(find.byType(NestBrandMark), findsOneWidget);
        expect(find.byType(NestIconTile), findsNothing);
      });

      testWidgets('an empty state with an icon keeps its tile', (tester) async {
        await pumpKit(
          tester,
          const NestEmptyView(
            title: 'Nothing yet',
            message: 'Add the first.',
            icon: Icons.search_off,
          ),
          brightness: brightness,
        );
        expect(find.byIcon(Icons.search_off), findsOneWidget);
        expect(find.byType(NestBrandMark), findsNothing);
      });
    });
  }

  test('the aspect ratios match the files the extractor wrote', () {
    // `tools/brand/extract_brand_assets.py` owns the files; if it is rerun on
    // a new logo and the shapes change, the layout constants must follow or
    // everything under the nest jumps when it decodes.
    for (final (path, aspect) in [
      (NestBrandAssets.mark, NestBrandAssets.markAspect),
      (NestBrandAssets.wordmark, NestBrandAssets.wordmarkAspect),
    ]) {
      final header = ByteData.sublistView(File(path).readAsBytesSync(), 16, 24);
      final width = header.getUint32(0);
      final height = header.getUint32(4);
      expect(width / height, closeTo(aspect, 0.001), reason: path);
    }
  });
}
