import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_pick.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../lunch_box/ui/lunch_picker_sheet.dart';
import '../model/planned_week.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_item_pill.dart';

/// One child's week on the review: whose it is, how much is new, and five
/// school days of compartments — what was packed already, quiet; what the
/// plan adds, in the slot's colour, a tap from being swapped through the
/// ordinary picker, ranked for this child with the unsafe unpickable
/// (lunch-box ADR-0001, ADR-0003).
class PlanWeekChildCard extends StatelessWidget {
  const PlanWeekChildCard({
    required this.planned,
    required this.week,
    required this.isEditable,
    super.key,
  });

  final PlannedChildWeek planned;
  final LunchWeek week;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final member = planned.child.member;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestAvatar(name: member.displayName, color: member.color),
              const SizedBox(width: NestSpace.md),
              Expanded(child: Text(member.displayName, style: nest.text.title)),
              NestTag(
                label: PlanWeekCopy.newForChild(planned.added.length),
                tone: planned.added.isEmpty
                    ? NestTagTone.neutral
                    : NestTagTone.success,
              ),
            ],
          ),
          for (final day in week.schoolDays) ...[
            const SizedBox(height: NestSpace.lg),
            Text(
              NestDates.weekdayName(day),
              style: nest.text.caption.copyWith(
                color: nest.colors.inkSecondary,
              ),
            ),
            const SizedBox(height: NestSpace.xs),
            Wrap(
              spacing: NestSpace.xs,
              runSpacing: NestSpace.xs,
              children: [
                for (final slot in LunchSlot.values)
                  ?_pillFor(
                    context,
                    day.weekday,
                    slot,
                    NestDates.weekdayName(day),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget? _pillFor(BuildContext context, int day, LunchSlot slot, String name) {
    final existing = planned.existingAt(day, slot);
    if (existing != null) {
      return PlanWeekItemPill(
        slot: slot,
        look: PillLook.existing,
        name: existing.name,
      );
    }
    final added = planned.addedAt(day, slot);
    if (added == null && !slot.isAutoFilledOn(day)) return null;
    return PlanWeekItemPill(
      key: ValueKey('plan-pill-${planned.childId}-$day-${slot.name}'),
      slot: slot,
      look: added == null ? PillLook.empty : PillLook.added,
      name: added?.item.name,
      origin: added?.origin,
      onTap: isEditable
          ? () => _swap(context, day: day, slot: slot, dayName: name)
          : null,
    );
  }

  Future<void> _swap(
    BuildContext context, {
    required int day,
    required LunchSlot slot,
    required String dayName,
  }) async {
    final controller = context.read<PlanWeekController>();
    final board = controller.board;
    if (board is! AsyncData<LunchBoard>) return;
    final childWeek = board.value.childWeek(planned.childId);
    if (childWeek == null) return;
    final current = planned.addedAt(day, slot);
    final choice = await showLunchPickerSheet(
      context: context,
      slot: slot,
      dayName: dayName,
      childName: planned.child.member.displayName,
      ranked: childWeek.rank(slot, board.value.library),
      current: current == null ? null : LunchPick.of(current.item),
    );
    final key = LunchPlan.slotKey(day, slot);
    switch (choice) {
      case null:
        return;
      case LunchItemChosen(:final item):
        controller.swapLunch(planned.childId, key, item);
      case LunchItemAdded(:final draft):
        await controller.addAndSwap(planned.childId, key, draft);
      case LunchSlotCleared():
        controller.swapLunch(planned.childId, key, null);
    }
  }
}
