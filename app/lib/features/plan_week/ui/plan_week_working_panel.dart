import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/ui/art/lunch_glyph.dart';

/// The model is working: the nest with the five compartments settling round
/// it, and a line typing out what is happening — so a wait of a few seconds
/// reads as work being done, not a spinner (`FE-08`). The orbit arrives once
/// and rests (design-system ADR-0002); under reduce-motion it is simply
/// there.
class PlanWeekWorkingPanel extends StatelessWidget {
  const PlanWeekWorkingPanel({
    required this.title,
    required this.line,
    this.progress,
    super.key,
  });

  final String title;
  final String line;

  /// How far it has got, when that can be counted.
  final String? progress;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: title,
      child: ListView(
        children: [
          const SizedBox(height: NestSpace.xl),
          Center(
            child: NestOrbit(
              semanticsLabel: title,
              centre: const NestBrandMark(),
              items: [
                for (final (index, slot) in LunchSlot.values.indexed)
                  NestOrbitItem(
                    ring: NestOrbitRing.outer,
                    turns: (index + 0.5) / LunchSlot.values.length,
                    child: LunchSlotTile(slot: slot),
                  ),
              ],
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          Text(title, textAlign: TextAlign.center, style: nest.text.headline),
          const SizedBox(height: NestSpace.sm),
          NestTypewriterText(
            text: line,
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
          if (progress case final progress?) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              progress,
              textAlign: TextAlign.center,
              style: nest.text.caption,
            ),
          ],
        ],
      ),
    );
  }
}
