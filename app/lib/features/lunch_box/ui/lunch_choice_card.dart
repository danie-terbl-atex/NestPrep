import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_slot.dart';
import 'art/lunch_glyph.dart';

/// One thing a child can choose (lunch-box ADR-0008): big, drawn, one tap.
/// Chosen, it pops, takes the tick's teal and a tick — a change of state the
/// motion explains, and zero under reduce-motion (`FE-15`); the tick and the
/// words say it without the colour (`FE-13`).
class LunchChoiceCard extends StatelessWidget {
  const LunchChoiceCard({
    required this.slot,
    required this.name,
    required this.isChosen,
    required this.onTap,
    super.key,
  });

  final LunchSlot slot;
  final String name;
  final bool isChosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final motion = NestMotion.of(context);
    return Semantics(
      button: true,
      selected: isChosen,
      label: LunchKidPicksCopy.optionLabel(name, isChosen),
      excludeSemantics: true,
      // Chosen, it pops in from a little smaller and settles at its own
      // size — never larger, so a card as wide as the screen stays in it.
      child: TweenAnimationBuilder<double>(
        key: ValueKey(isChosen),
        tween: Tween(begin: isChosen ? 0.92 : 1, end: 1),
        duration: motion.standard,
        curve: NestMotion.celebrate,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Material(
          color: isChosen ? c.accentSoft : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NestRadius.xl),
            side: BorderSide(
              color: isChosen ? c.accent : c.outline,
              width: isChosen ? NestStroke.focus : NestStroke.hairline,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(NestRadius.xl),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(NestSpace.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LunchSlotTile(slot: slot, size: NestSize.avatarLarge),
                      if (isChosen)
                        PositionedDirectional(
                          end: -NestSpace.sm,
                          top: -NestSpace.sm,
                          child: Icon(
                            LucideIcons.circleCheck,
                            color: c.accent,
                            size: NestSize.iconLarge,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: NestSpace.sm),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: nest.text.bodyStrong.copyWith(
                      color: isChosen ? c.accentInk : c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
