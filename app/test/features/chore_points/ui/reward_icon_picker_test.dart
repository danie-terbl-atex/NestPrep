import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/model/reward.dart';
import 'package:nestprep/features/chore_points/ui/reward_icon_picker.dart';

import '../../../support/pump_kit.dart';

/// The reward's picture picker shows which picture is chosen with more than
/// a colour: one tick, on that picture, in both themes.
void main() {
  const chosen = ValueKey('reward-icon-chosen');

  Finder tile(RewardIcon icon) =>
      find.byKey(ValueKey('reward-icon-${icon.name}'));

  for (final brightness in bothThemes) {
    testWidgets('ticks the chosen picture and no other — $brightness', (
      tester,
    ) async {
      await pumpKit(
        tester,
        RewardIconPicker(selected: RewardIcon.movie, onChanged: (_) {}),
        brightness: brightness,
      );

      expect(find.byKey(chosen), findsOneWidget);
      expect(
        find.descendant(
          of: tile(RewardIcon.movie),
          matching: find.byKey(chosen),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tile(RewardIcon.gift),
          matching: find.byKey(chosen),
        ),
        findsNothing,
      );
    });
  }

  testWidgets('the tick follows the choice', (tester) async {
    var selected = RewardIcon.gift;
    await pumpKit(
      tester,
      StatefulBuilder(
        builder: (context, setState) => RewardIconPicker(
          selected: selected,
          onChanged: (icon) => setState(() => selected = icon),
        ),
      ),
    );

    await tester.tap(tile(RewardIcon.game));
    await tester.pump();

    expect(selected, RewardIcon.game);
    expect(
      find.descendant(of: tile(RewardIcon.game), matching: find.byKey(chosen)),
      findsOneWidget,
    );
    expect(find.byKey(chosen), findsOneWidget);
  });
}
