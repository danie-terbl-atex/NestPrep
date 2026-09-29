import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';
import '../model/kid_day.dart';
import 'kid_chore_tile.dart';
import 'kid_food_card.dart';
import 'kid_hero_card.dart';
import 'kid_moment_card.dart';

/// A kid's day, top to bottom: who they are and how far along they are, their
/// jobs, and today's food (accounts ADR-0003) — each section only when the
/// grant their profile holds opens it (accounts ADR-0004).
///
/// "No jobs" is part of the view rather than a replacement for it: the food is
/// still worth seeing on a day with nothing to do (`FE-08`). A grant that opens
/// neither says so, kindly, rather than showing a blank page.
class KidDayView extends StatelessWidget {
  const KidDayView({required this.day, required this.onToggle, super.key});

  final KidDay day;
  final void Function(int index) onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(child: KidHeroCard(day: day)),
        if (day.areas.chores) ...[
          const SizedBox(height: NestSpace.xxl),
          const NestSectionHeader(title: KidCopy.choresTitle),
          const SizedBox(height: NestSpace.sm),
          if (!day.hasChores)
            const KidMomentCard(
              icon: Icons.wb_sunny_rounded,
              tint: NestTileTint.sky,
              title: KidCopy.choresNone,
              message: KidCopy.choresNoneBody,
            ),
          for (final (index, chore) in day.chores.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestRiseIn(
                index: index + 1,
                child: KidChoreTile(
                  key: ValueKey(chore.key),
                  chore: chore,
                  isOverdue: chore.isOverdue(day.today),
                  onToggle: day.areas.canTick ? () => onToggle(index) : null,
                ),
              ),
            ),
          if (day.isAllDone)
            const KidMomentCard(
              icon: Icons.emoji_events_rounded,
              tint: NestTileTint.peach,
              title: KidCopy.choresAllDone,
              message: KidCopy.choresAllDoneBody,
            ),
        ],
        if (day.areas.food) ...[
          const SizedBox(height: NestSpace.xxl),
          KidFoodCard(meals: day.meals),
        ],
        if (!day.areas.showsAnything) ...[
          const SizedBox(height: NestSpace.xxl),
          const KidMomentCard(
            icon: Icons.lock_clock_rounded,
            tint: NestTileTint.sky,
            title: KidCopy.nothingShownTitle,
            message: KidCopy.nothingShownBody,
          ),
        ],
      ],
    );
  }
}
