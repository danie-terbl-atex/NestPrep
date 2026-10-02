import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/family_route.dart';
import '../../../../app/lunch_route.dart';
import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../../../shared/format/nest_dates.dart';
import '../../../../shared/ui/back_leading.dart';
import '../../../household/model/household_area.dart';
import '../../../household/model/household_view.dart';
import '../../model/lunch_board.dart';
import '../../state/lunch_board_controller.dart';
import 'lunch_share_body.dart';

/// Share the week (lunch-box ADR-0005): the week the lunch board is on, as a
/// card for Instagram, TikTok or WhatsApp, or as a printable planner.
///
/// It reads the board's own controller — the shell above both keeps it — so
/// opening it reads nothing new. Only somebody who plans the lunches may
/// share them; a deep link from anybody else finds the door shut.
class LunchShareScreen extends StatelessWidget {
  const LunchShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final board = context.watch<LunchBoardController>();
    final view = context.watch<HouseholdView>();
    final canShare = view.permissions.canEdit(HouseholdArea.lunch);
    return NestScaffold(
      title: LunchShareCopy.title,
      subtitle: LunchCopy.weekOf(NestDates.schoolWeekRange(board.week.monday)),
      leading: backLeading(context),
      body: canShare
          ? NestAsyncView<LunchBoard>(
              state: board.board,
              isEmpty: (value) => !value.hasChildren,
              onRetry: board.retry,
              emptyBuilder: (context) => NestEmptyView(
                icon: LucideIcons.sandwich,
                title: LunchCopy.noChildrenTitle,
                message: LunchCopy.noChildrenBody,
                actionLabel: LunchCopy.openFamily,
                onAction: () =>
                    context.push(FamilyRoute.pathFor(view.household.id)),
              ),
              dataBuilder: (context, value) => LunchShareBody(board: value),
            )
          : NestEmptyView(
              icon: LucideIcons.lock,
              title: LunchShareCopy.title,
              message: LunchShareCopy.onlyPlanners,
              actionLabel: LunchCopy.backToLunches,
              onAction: () => context.canPop()
                  ? context.pop()
                  : context.go(LunchRoute.pathFor(view.household.id)),
            ),
    );
  }
}
