import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// Two views of one place, side by side (design-system ADR-0015): the choice
/// is its owner's, each segment a selectable node, never colour alone.
void main() {
  Widget control({required int selected, ValueChanged<int>? onSelect}) =>
      SizedBox(
        width: 360,
        child: NestSegmentedControl<int>(
          segments: const [
            NestSegment(value: 0, label: 'Recipes', icon: Icons.book),
            NestSegment(value: 1, label: 'This week'),
          ],
          selected: selected,
          onSelect: onSelect ?? (_) {},
        ),
      );

  for (final brightness in bothThemes) {
    testWidgets('says which is chosen to a screen reader — $brightness', (
      tester,
    ) async {
      await pumpKit(tester, control(selected: 1), brightness: brightness);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.bySemanticsLabel('This week')),
        matchesSemantics(
          label: 'This week',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Recipes')),
        isNot(matchesSemantics(isSelected: true)),
      );
      handle.dispose();
    });
  }

  testWidgets('reports a tap and holds no choice of its own', (tester) async {
    final chosen = <int>[];
    await pumpKit(tester, control(selected: 0, onSelect: chosen.add));
    await tester.tap(find.text('This week'));
    await tester.pump();
    expect(chosen, [1]);
    final selected = tester.widget<NestSegmentedControl<int>>(
      find.byType(NestSegmentedControl<int>),
    );
    expect(selected.selected, 0, reason: 'the owner moves it, not the tap');
  });

  testWidgets('each segment is at least the touch-target floor', (
    tester,
  ) async {
    await pumpKit(tester, control(selected: 0));
    for (final label in ['Recipes', 'This week']) {
      final box = tester.getSize(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      expect(box.height, greaterThanOrEqualTo(NestSize.controlSmall));
    }
  });

  testWidgets('a name too long for half a phone at 200% yields', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          theme: nestThemeData(NestTheme.dark()),
          home: Scaffold(body: Center(child: control(selected: 0))),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
