import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_board.dart';
import '../model/lunch_pantry_week.dart';
import '../state/lunch_pantry_controller.dart';

/// Today's box, in the bag (lunch-box ADR-0006): one tap takes what is in it
/// out of the pantry, once, and can be undone. Only on a school day, and
/// only when today's box has something in it.
class LunchPackedToday extends StatelessWidget {
  const LunchPackedToday({
    required this.board,
    required this.childWeek,
    required this.pantry,
    super.key,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;
  final LunchPantryWeek pantry;

  @override
  Widget build(BuildContext context) {
    final today = childWeek.days.where((day) => day.isToday).firstOrNull;
    if (today == null || today.box.isEmpty) return const SizedBox.shrink();
    final controller = context.read<LunchPantryController>();
    final isPacked = pantry.isPacked(childWeek.childId, today.date);
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestToneRow(
            icon: isPacked
                ? Icons.check_circle_rounded
                : Icons.backpack_outlined,
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
              icon: isPacked ? Icons.undo_rounded : Icons.backpack_outlined,
              variant: isPacked
                  ? NestButtonVariant.ghost
                  : NestButtonVariant.tonal,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: isPacked
                  ? () => controller.unmarkPacked(
                      childId: childWeek.childId,
                      date: today.date,
                    )
                  : () => controller.markPacked(
                      childId: childWeek.childId,
                      date: today.date,
                      box: today.box,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
