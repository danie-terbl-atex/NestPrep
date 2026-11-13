import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// Premium's seal, card and the bar's trim (subscriptions ADR-0007): Butter
/// with Ink in both themes, and a card that is a control only when it has
/// somewhere to go.
void main() {
  const items = [
    NestBottomBarItem(icon: LucideIcons.sun, label: 'Today'),
    NestBottomBarItem(icon: LucideIcons.layoutGrid, label: 'More'),
  ];

  ShapeDecoration barDecoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(NestBottomBar),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((box) => box.decoration)
      .whereType<ShapeDecoration>()
      .first;

  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('the seal is Butter with Ink, and reads as its label', (
        tester,
      ) async {
        await pumpKit(
          tester,
          const NestPremiumSeal(label: 'Premium'),
          brightness: brightness,
        );
        final text = tester.widget<Text>(find.text('Premium'));
        expect(text.style?.color, NestColors.inkBrand);
        expect(find.bySemanticsLabel('Premium'), findsOneWidget);
      });

      testWidgets('the card says its three lines and goes where it is told', (
        tester,
      ) async {
        var taps = 0;
        await pumpKit(
          tester,
          SizedBox(
            width: 320,
            child: NestPremiumCard(
              title: 'nestprep Premium',
              body: 'Every part of nestprep.',
              detail: 'Renews on 3 December',
              onTap: () => taps++,
            ),
          ),
          brightness: brightness,
        );
        await tester.pumpAndSettle();
        for (final line in [
          'nestprep Premium',
          'Every part of nestprep.',
          'Renews on 3 December',
        ]) {
          expect(
            tester.widget<Text>(find.text(line)).style?.color,
            NestColors.inkBrand,
            reason: line,
          );
        }
        expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
        await tester.tap(find.text('nestprep Premium'));
        expect(taps, 1);
      });

      testWidgets('a card with nowhere to go is not a control', (tester) async {
        await pumpKit(
          tester,
          const SizedBox(
            width: 320,
            child: NestPremiumCard(
              title: 'nestprep Premium',
              body: 'All of it',
            ),
          ),
          brightness: brightness,
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
        expect(find.byType(NestPressable), findsNothing);
      });

      testWidgets('the bar wears a Butter trim only when asked', (
        tester,
      ) async {
        for (final hasTrim in [false, true]) {
          await pumpKit(
            tester,
            NestBottomBar(
              items: items,
              selectedIndex: 0,
              onSelect: (_) {},
              hasPremiumTrim: hasTrim,
            ),
            brightness: brightness,
          );
          final side = (barDecoration(tester).shape as StadiumBorder).side;
          expect(
            side,
            hasTrim
                ? const BorderSide(
                    color: NestColors.butter,
                    width: NestSpace.xxs,
                  )
                : BorderSide.none,
          );
        }
      });
    });
  }

  testWidgets('the card can be tapped while its sheen is still crossing', (
    tester,
  ) async {
    var taps = 0;
    await pumpKit(
      tester,
      SizedBox(
        width: 320,
        child: NestPremiumCard(
          title: 'nestprep Premium',
          body: 'All of it',
          onTap: () => taps++,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('nestprep Premium'));
    expect(taps, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('under reduce-motion the card has no sheen at all', (
    tester,
  ) async {
    await pumpKit(
      tester,
      const SizedBox(
        width: 320,
        child: NestPremiumCard(title: 'nestprep Premium', body: 'All of it'),
      ),
      reduceMotion: true,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });
}
