import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

void main() {
  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('a text field shows its label, hint and error', (
        tester,
      ) async {
        await pumpKit(
          tester,
          const NestTextField(
            label: 'Name',
            hint: 'Type it',
            errorText: 'Required',
          ),
          brightness: brightness,
        );
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Type it'), findsOneWidget);
        expect(find.text('Required'), findsOneWidget);
      });

      testWidgets('a chip reports selection and taps', (tester) async {
        var taps = 0;
        await pumpKit(
          tester,
          NestChip(label: 'Week', isSelected: true, onTap: () => taps++),
          brightness: brightness,
        );
        await tester.tap(find.text('Week'));
        expect(taps, 1);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Week'))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
      });

      testWidgets(
        'an avatar always draws the initial with the name as its label',
        (tester) async {
          await pumpKit(
            tester,
            const NestAvatar(name: 'monique', color: MemberColor.mint),
            brightness: brightness,
          );
          expect(find.text('M'), findsOneWidget);
          expect(find.bySemanticsLabel('monique'), findsOneWidget);
        },
      );

      testWidgets('an icon button is labelled and meets the touch target', (
        tester,
      ) async {
        await pumpKit(
          tester,
          NestIconButton(
            icon: LucideIcons.plus,
            label: 'Add',
            onPressed: () {},
          ),
          brightness: brightness,
        );
        expect(find.bySemanticsLabel('Add'), findsOneWidget);
        expect(
          tester.getSize(find.byType(NestIconButton)).shortestSide,
          greaterThanOrEqualTo(48),
        );
      });

      testWidgets('a list row renders title, subtitle and taps', (
        tester,
      ) async {
        var taps = 0;
        await pumpKit(
          tester,
          NestListRow(title: 'Milk', subtitle: '2 litres', onTap: () => taps++),
          brightness: brightness,
        );
        await tester.tap(find.text('Milk'));
        expect(taps, 1);
        expect(find.text('2 litres'), findsOneWidget);
      });

      testWidgets('the bottom bar selects by tap and labels every item', (
        tester,
      ) async {
        var selected = 0;
        await pumpKit(
          tester,
          NestBottomBar(
            selectedIndex: 0,
            onSelect: (index) => selected = index,
            items: const [
              NestBottomBarItem(
                icon: LucideIcons.house,
                selectedIcon: LucideIcons.house,
                label: 'Home',
              ),
              NestBottomBarItem(
                icon: LucideIcons.list,
                selectedIcon: LucideIcons.list,
                label: 'Lists',
              ),
            ],
          ),
          brightness: brightness,
        );
        await tester.tap(find.bySemanticsLabel('Lists'));
        expect(selected, 1);
      });
    });
  }

  testWidgets('the skeleton is still when motion is reduced', (tester) async {
    await pumpKit(tester, const NestSkeleton(), reduceMotion: true);
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(NestSkeleton),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value,
      1,
    );
  });
}
