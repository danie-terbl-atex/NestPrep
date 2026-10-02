import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/lunch_board.dart';
import '../model/lunch_day.dart';
import '../model/lunch_slot.dart';
import 'lunch_eaten_bar.dart';
import 'lunch_flows.dart';
import 'lunch_slot_row.dart';

/// One school day of one child's week: its five compartments, each a tap to
/// swap, and — once the day has happened — whether it came home eaten. An
/// empty compartment says what it is waiting for rather than being a gap, so
/// the week always reads as a grid and the first box has a way in (`FE-08`).
class LunchDayCard extends StatelessWidget {
  const LunchDayCard({
    required this.board,
    required this.childWeek,
    required this.day,
    required this.canEdit,
    super.key,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;
  final LunchDay day;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final feedback = day.feedback;
    return NestCard(
      variant: day.isToday ? NestCardVariant.tinted : NestCardVariant.flat,
      padding: const EdgeInsets.fromLTRB(
        NestSpace.lg,
        NestSpace.md,
        NestSpace.sm,
        NestSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  NestDates.dayInARun(day.date, board.today),
                  style: nest.text.bodyStrong.copyWith(
                    color: day.isToday ? c.accentInk : c.ink,
                  ),
                ),
              ),
              if (day.hasUnsafe)
                const Padding(
                  padding: EdgeInsets.only(right: NestSpace.xs),
                  child: NestTag(
                    label: LunchCopy.unsafeTag,
                    tone: NestTagTone.danger,
                    icon: LucideIcons.ban,
                  ),
                ),
              if (canEdit)
                NestIconButton(
                  icon: LucideIcons.ellipsis,
                  label: LunchCopy.dayActions,
                  variant: NestIconButtonVariant.plain,
                  onPressed: () => LunchFlows.dayMenu(
                    context,
                    childWeek: childWeek,
                    day: day,
                  ),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xs),
          for (final slot in LunchSlot.values)
            Padding(
              padding: const EdgeInsets.only(right: NestSpace.sm),
              child: LunchSlotRow(
                key: ValueKey('${day.date.iso}-${slot.name}'),
                slot: slot,
                pick: day.box[slot],
                concerns: day.concernsAt(slot),
                verdict: feedback?.isMarkedOnItsOwn(slot) ?? false
                    ? feedback?.verdictFor(slot)
                    : null,
                onTap: canEdit
                    ? () => LunchFlows.pickSlot(
                        context,
                        board: board,
                        childWeek: childWeek,
                        day: day,
                        slot: slot,
                      )
                    : null,
              ),
            ),
          if (day.hasHappened && !day.box.isEmpty) ...[
            const SizedBox(height: NestSpace.md),
            Padding(
              padding: const EdgeInsets.only(right: NestSpace.sm),
              child: LunchEatenBar(
                feedback: feedback,
                onMark: canEdit
                    ? (verdict) => LunchFlows.markBox(
                        context,
                        childWeek: childWeek,
                        day: day,
                        verdict: verdict,
                      )
                    : null,
                onMarkItems: canEdit
                    ? () => LunchFlows.markItems(
                        context,
                        childWeek: childWeek,
                        day: day,
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
