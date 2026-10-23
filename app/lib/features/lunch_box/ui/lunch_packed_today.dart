import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_board.dart';
import '../model/lunch_day.dart';
import '../state/lunch_pantry_controller.dart';

/// Today's box, in the bag (lunch-box ADR-0006): one tap takes what is in it
/// out of the pantry, once, and can be undone. It sits with the day on show
/// (ADR-0022), so only when that day is today and its box has something in
/// it. Silent while the pantry loads or fails — the week's pantry planning
/// is where that failure is shown with a retry.
class LunchPackedToday extends StatelessWidget {
  const LunchPackedToday({
    required this.childWeek,
    required this.day,
    super.key,
  });

  final LunchChildWeek childWeek;
  final LunchDay day;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchPantryController>();
    final pantry = switch (controller.pantry) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (pantry == null || !day.isToday || day.box.isEmpty) {
      return const SizedBox.shrink();
    }
    final isPacked = pantry.isPacked(childWeek.childId, day.date);
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestToneRow(
            icon: isPacked ? LucideIcons.circleCheck : LucideIcons.backpack,
            tone: isPacked ? NestTagTone.success : NestTagTone.neutral,
            title: isPacked
                ? LunchPantryCopy.packedDone
                : LunchPantryCopy.packedQuestion,
            subtitle: isPacked ? null : LunchPantryCopy.markPackedHint,
          ),
          const SizedBox(height: NestSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NestButton(
              label: isPacked
                  ? LunchPantryCopy.undoPacked
                  : LunchPantryCopy.markPacked,
              icon: isPacked ? LucideIcons.undo2 : LucideIcons.backpack,
              variant: isPacked
                  ? NestButtonVariant.ghost
                  : NestButtonVariant.tonal,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: isPacked
                  ? () => controller.unmarkPacked(
                      childId: childWeek.childId,
                      date: day.date,
                    )
                  : () => controller.markPacked(
                      childId: childWeek.childId,
                      date: day.date,
                      box: day.box,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
