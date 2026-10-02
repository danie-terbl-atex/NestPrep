import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_planning_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_choice_day.dart';
import '../../lunch_box/state/lunch_choose_controller.dart';

/// On a kid's home: a grown-up has given them lunch to choose (lunch-box
/// ADR-0008). One bright card, how many days are waiting, and the way in.
/// Nothing at all while it loads, when nothing is offered, or when the read
/// fails — the chooser itself shows that failure with a retry; this card is
/// an invitation, not a view.
class KidLunchPicksCard extends StatelessWidget {
  const KidLunchPicksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchChooseController?>();
    final days = switch (controller?.days) {
      AsyncData(:final value) => value,
      _ => const <LunchChoiceDay>[],
    };
    if (days.isEmpty) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    final waiting = days.where((day) => !day.isComplete).length;
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Row(
        children: [
          const NestIconTile(
            icon: LucideIcons.pointer,
            tint: NestTileTint.butter,
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LunchKidPicksCopy.kidCardTitle, style: nest.text.title),
                Text(
                  waiting == 0
                      ? LunchKidPicksCopy.kidCardAllDone
                      : LunchKidPicksCopy.kidCardBody(waiting),
                  style: nest.text.bodySecondary,
                ),
                const SizedBox(height: NestSpace.sm),
                NestButton(
                  label: LunchKidPicksCopy.kidCardOpen,
                  icon: LucideIcons.arrowRight,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: () =>
                      context.push(LunchPlanningRoute.kidChoosePath),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
