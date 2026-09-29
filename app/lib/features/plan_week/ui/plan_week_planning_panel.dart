import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/ui/art/lunch_glyph.dart';

/// The week is being planned: the nest with the five compartments and a
/// dinner plate settling around it, and a line typing out what is happening
/// — so a wait of a few seconds reads as work being done, not a spinner
/// (`FE-08`). The orbit arrives once and rests (design-system ADR-0002);
/// under reduce-motion it is simply there.
class PlanWeekPlanningPanel extends StatelessWidget {
  const PlanWeekPlanningPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: PlanWeekCopy.planningTitle,
      child: ListView(
        children: [
          const SizedBox(height: NestSpace.xl),
          Center(
            child: NestOrbit(
              semanticsLabel: PlanWeekCopy.planningOrbitLabel,
              centre: const NestBrandMark(),
              items: [
                for (final (index, slot) in LunchSlot.values.indexed)
                  NestOrbitItem(
                    ring: NestOrbitRing.outer,
                    turns: (index + 0.5) / (LunchSlot.values.length + 1),
                    child: LunchSlotTile(slot: slot),
                  ),
                NestOrbitItem(
                  ring: NestOrbitRing.outer,
                  turns:
                      (LunchSlot.values.length + 0.5) /
                      (LunchSlot.values.length + 1),
                  child: const NestIconTile(
                    icon: Icons.dinner_dining_outlined,
                    tint: NestTileTint.peach,
                    size: NestSize.avatarMedium,
                    iconSize: NestSize.iconMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          Text(
            PlanWeekCopy.planningTitle,
            textAlign: TextAlign.center,
            style: nest.text.headline,
          ),
          const SizedBox(height: NestSpace.sm),
          NestTypewriterText(
            text: PlanWeekCopy.planningLine,
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}
