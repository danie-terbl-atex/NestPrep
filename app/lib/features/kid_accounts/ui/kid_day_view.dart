import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../chore_points/model/kid_chore_note.dart';
import '../../todos/model/task_occurrence.dart';
import '../model/kid_day.dart';
import 'kid_chore_tile.dart';
import 'kid_food_card.dart';
import 'kid_hero_card.dart';
import 'kid_lunch_card.dart';
import 'kid_moment_card.dart';

/// A kid's day, top to bottom: who they are and how far along they are, their
/// jobs, their lunch box, and today's food (accounts ADR-0003) — each section only when the
/// grant their profile holds opens it (accounts ADR-0004).
///
/// "No jobs" is part of the view rather than a replacement for it: the food is
/// still worth seeing on a day with nothing to do (`FE-08`). A grant that opens
/// neither says so, kindly, rather than showing a blank page.
///
/// Stars (todos ADR-0003) arrive as two slots the home fills when the grant
/// shows jobs — the stars card under the greeting and the reward shelf under
/// the jobs — and a note per job saying what it is worth.
class KidDayView extends StatelessWidget {
  const KidDayView({
    required this.day,
    required this.onToggle,
    this.stars,
    this.shelf,
    this.lunchPicks,
    this.noteFor = _noNote,
    super.key,
  });

  final KidDay day;
  final void Function(int index) onToggle;
  final Widget? stars;
  final Widget? shelf;

  /// Lunch to choose, when a grown-up offered some (lunch-box ADR-0008).
  final Widget? lunchPicks;
  final KidChoreNote Function(TaskOccurrence chore) noteFor;

  static KidChoreNote _noNote(TaskOccurrence chore) =>
      KidChoreNote.of(chore, null);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(child: KidHeroCard(day: day)),
        if (stars case final stars?) ...[
          const SizedBox(height: NestSpace.lg),
          NestRiseIn(index: 1, child: stars),
        ],
        if (day.areas.chores) ...[
          const SizedBox(height: NestSpace.xxl),
          const NestSectionHeader(title: KidCopy.choresTitle),
          const SizedBox(height: NestSpace.sm),
          if (!day.hasChores)
            const KidMomentCard(
              icon: Icons.wb_sunny_rounded,
              tint: NestTileTint.lilac,
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
                  note: noteFor(chore),
                ),
              ),
            ),
          if (day.isAllDone)
            const KidMomentCard(
              icon: Icons.emoji_events_rounded,
              tint: NestTileTint.butter,
              title: KidCopy.choresAllDone,
              message: KidCopy.choresAllDoneBody,
            ),
        ],
        if (lunchPicks case final picks? when day.areas.lunch) ...[
          const SizedBox(height: NestSpace.xxl),
          picks,
        ],
        // Their own box, before the household's meals: it is the food they
        // carry (lunch-box ADR-0004).
        if (day.lunchBox case final box?) ...[
          const SizedBox(height: NestSpace.xxl),
          NestRiseIn(
            index: day.chores.length + 1,
            child: KidLunchCard(box: box),
          ),
        ],
        if (shelf case final shelf?) ...[
          const SizedBox(height: NestSpace.xxl),
          shelf,
        ],
        if (day.areas.food) ...[
          const SizedBox(height: NestSpace.xxl),
          KidFoodCard(meals: day.meals),
        ],
        if (!day.areas.showsAnything) ...[
          const SizedBox(height: NestSpace.xxl),
          const KidMomentCard(
            icon: Icons.lock_clock_rounded,
            tint: NestTileTint.lilac,
            title: KidCopy.nothingShownTitle,
            message: KidCopy.nothingShownBody,
          ),
        ],
      ],
    );
  }
}
