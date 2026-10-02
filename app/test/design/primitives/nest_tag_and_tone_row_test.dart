import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// The two primitives family profiles added, and the two changes it made to
/// existing ones: a chip that can say what tapping it does, and a chip and an
/// icon button that are their own node to a screen reader.
void main() {
  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('a tag reads its label in every tone', (tester) async {
        await pumpKit(
          tester,
          Wrap(
            children: [
              for (final tone in NestTagTone.values)
                NestTag(
                  label: 'Severe',
                  tone: tone,
                  icon: LucideIcons.triangleAlert,
                ),
            ],
          ),
          brightness: brightness,
        );
        expect(find.text('Severe'), findsNWidgets(NestTagTone.values.length));
        expect(tester.takeException(), isNull);
      });

      testWidgets('a tone row is tappable and says its title and line', (
        tester,
      ) async {
        var taps = 0;
        await pumpKit(
          tester,
          SizedBox(
            width: 320,
            child: NestToneRow(
              icon: LucideIcons.siren,
              tone: NestTagTone.danger,
              title: 'Peanuts',
              subtitle: 'Pen in the bag',
              trailing: const NestTag(label: 'Severe'),
              onTap: () => taps++,
            ),
          ),
          brightness: brightness,
        );
        await tester.tap(find.text('Peanuts'));
        expect(taps, 1);
        expect(find.text('Pen in the bag'), findsOneWidget);
        expect(
          tester.getSize(find.byType(NestToneRow)).height,
          greaterThanOrEqualTo(NestSize.controlSmall),
        );
      });
    });
  }

  testWidgets('a chip can carry a cross and say what tapping it does', (
    tester,
  ) async {
    var taps = 0;
    await pumpKit(
      tester,
      NestChip(
        label: 'Pasta',
        trailingIcon: LucideIcons.x,
        semanticLabel: 'Remove Pasta',
        onTap: () => taps++,
      ),
    );
    expect(find.byIcon(LucideIcons.x), findsOneWidget);
    expect(find.bySemanticsLabel('Remove Pasta'), findsOneWidget);
    await tester.tap(find.text('Pasta'));
    expect(taps, 1);
  });

  testWidgets('a chip beside a heading is its own node, not part of it', (
    tester,
  ) async {
    await pumpKit(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Kid Parker'),
          NestChip(label: 'Child', onTap: () {}),
          NestIconButton(
            icon: LucideIcons.plus,
            label: 'Add',
            onPressed: () {},
          ),
        ],
      ),
    );
    final chip = tester.getSemantics(find.bySemanticsLabel('Child'));
    expect(chip.label, 'Child', reason: 'not "Kid Parker\\nChild"');
    expect(chip.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(tester.getSemantics(find.bySemanticsLabel('Add')).label, 'Add');
  });
}
