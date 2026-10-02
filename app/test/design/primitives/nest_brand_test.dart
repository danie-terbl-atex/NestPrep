import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../support/pump_kit.dart';

/// The brand in the kit (design-system ADR-0008): the arch mark, the Fraunces
/// wordmark, and the empty state that can show the mark.
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

      testWidgets('the wordmark is Fraunces in the theme ink', (tester) async {
        await pumpKit(
          tester,
          const NestWordmark(semanticsLabel: AppCopy.appName),
          brightness: brightness,
        );
        final ink = brightness == Brightness.dark
            ? NestColors.dark.ink
            : NestColors.light.ink;
        final text = tester.widget<Text>(find.byType(Text));
        expect(text.style?.color, ink);
        expect(text.style?.fontFamily, NestTextStyles.displayFamily);
      });

      testWidgets('the mark is square at the size it is given', (tester) async {
        await pumpKit(
          tester,
          const NestBrandMark(size: NestSize.brandMarkLarge),
          brightness: brightness,
        );
        expect(
          tester.getSize(find.byType(NestBrandMark)),
          const Size.square(NestSize.brandMarkLarge),
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
            icon: LucideIcons.searchX,
          ),
          brightness: brightness,
        );
        expect(find.byIcon(LucideIcons.searchX), findsOneWidget);
        expect(find.byType(NestBrandMark), findsNothing);
      });
    });
  }

  test('the painted mark matches the approved vector', () {
    final svg = File('assets/brand/nest_mark.svg').readAsStringSync();
    expect(svg, contains('rx="28"'));
    expect(svg, contains('fill="#F57B91"'));
    expect(svg, contains('stroke="#35252E"'));
    expect(NestColors.guava, const Color(0xFFF57B91));
    expect(NestColors.inkBrand, const Color(0xFF35252E));
  });
}
