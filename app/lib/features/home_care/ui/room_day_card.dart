import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/routine/room_day.dart';
import '../model/routine/routine_visit.dart';
import 'room_day_header.dart';
import 'translated_step_tile.dart';

/// One room on the helper's day (home-care ADR-0004): the room, big, how far
/// through, and every routine's items as tiles to tick with gloves on — in
/// her language, read aloud on a tap (ADR-0006).
class RoomDayCard extends StatelessWidget {
  const RoomDayCard({
    required this.day,
    required this.helperNameOf,
    required this.canTick,
    required this.onToggle,
    this.showsHelpers = false,
    super.key,
  });

  final RoomDay day;

  /// Who a routine is for, for a parent reading everybody's day.
  final String Function(RoutineVisit visit) helperNameOf;
  final bool Function(RoutineVisit visit) canTick;
  final void Function(RoutineVisit visit, String itemId) onToggle;

  /// Whether to say whose each routine is — a parent's view of the day.
  final bool showsHelpers;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoomDayHeader(day: day, isLarge: true),
          for (final visit in day.visits) ...[
            const SizedBox(height: NestSpace.lg),
            Text(visit.routine.name, style: nest.text.label),
            if (showsHelpers)
              Text(
                HomeCareRoutineCopy.forHelper(helperNameOf(visit)),
                style: nest.text.caption,
              ),
            const SizedBox(height: NestSpace.sm),
            for (final (index, item) in visit.routine.items.indexed) ...[
              TranslatedStepTile(
                key: ValueKey('${visit.routine.id}/${item.id}'),
                number: index + 1,
                english: item.text,
                isDone: visit.isItemDone(item.id),
                onToggle: canTick(visit)
                    ? () => onToggle(visit, item.id)
                    : null,
              ),
              const SizedBox(height: NestSpace.sm),
            ],
          ],
        ],
      ),
    );
  }
}
