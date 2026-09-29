import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../family_profiles/ui/family_section_card.dart';
import '../../family_profiles/ui/family_section_empty.dart';
import '../model/care_routine.dart';

/// A child's day as a carer follows it: each step at its time, in the order
/// of the day, with how to do it underneath.
class RoutineSection extends StatelessWidget {
  const RoutineSection({
    required this.routines,
    required this.onEdit,
    super.key,
  });

  final List<CareRoutine> routines;

  /// Null when the viewer may not change the card.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return FamilySectionCard(
      icon: Icons.schedule_outlined,
      tint: NestTileTint.sky,
      title: NannyCopy.routine,
      actionLabel: NannyCopy.editRoutine,
      onAction: onEdit,
      child: routines.isEmpty
          ? const FamilySectionEmpty(message: NannyCopy.noRoutine)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, routine) in routines.indexed)
                  Padding(
                    key: ValueKey(index),
                    padding: const EdgeInsets.only(bottom: NestSpace.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NestTag(
                          label: switch (routine.minuteOfDay) {
                            final int minutes => NestDates.timeOfDay(minutes),
                            null => NannyCopy.anyTime,
                          },
                          tone: routine.minuteOfDay == null
                              ? NestTagTone.neutral
                              : NestTagTone.accent,
                          icon: Icons.schedule,
                        ),
                        const SizedBox(width: NestSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(routine.label, style: nest.text.bodyStrong),
                              if (routine.note case final note?)
                                Text(note, style: nest.text.bodySecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
