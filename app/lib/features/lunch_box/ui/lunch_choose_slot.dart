import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_choice_day.dart';
import '../model/lunch_pick.dart';
import 'art/lunch_glyph.dart';
import 'lunch_choice_card.dart';

/// One compartment of the chooser: its name, drawn, and the two or three
/// cards to choose from — side by side where they fit, wrapping where they
/// do not, so large text on a small phone still reads (`FE-14`).
class LunchChooseSlot extends StatelessWidget {
  const LunchChooseSlot({
    required this.entry,
    required this.onChoose,
    super.key,
  });

  final LunchChoiceSlot entry;
  final ValueChanged<LunchPick> onChoose;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final chosen = entry.chosen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            LunchGlyph(slot: entry.slot),
            const SizedBox(width: NestSpace.sm),
            Expanded(
              child: Text(
                LunchCopy.slotName(entry.slot),
                style: nest.text.title,
              ),
            ),
            if (chosen != null)
              Icon(
                LucideIcons.star,
                size: NestSize.iconMedium,
                color: nest.colors.warning,
              ),
          ],
        ),
        const SizedBox(height: NestSpace.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = NestSpace.sm;
            // As many across as fit a card no narrower than twice its
            // drawing, grown with the text — so a long name at large text
            // gets a row of its own rather than breaking mid-word.
            final narrowest = MediaQuery.textScalerOf(context)
                .scale(NestSize.avatarLarge * 2);
            double widthFor(int across) =>
                (constraints.maxWidth - gap * (across - 1)) / across;
            var across = entry.options.length;
            while (across > 1 && widthFor(across) < narrowest) {
              across--;
            }
            final width = widthFor(across);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final option in entry.options)
                  SizedBox(
                    width: width,
                    child: LunchChoiceCard(
                      key: ValueKey(option.itemId),
                      slot: entry.slot,
                      name: option.name,
                      isChosen: chosen?.itemId == option.itemId,
                      onTap: () => onChoose(option),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
