import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../model/lunch_prep_list.dart';
import '../state/lunch_board_controller.dart';
import 'lunch_prep_row.dart';

/// The Sunday prep list (lunch-box ADR-0003): what the week's boxes, for
/// every child, need made ahead — and, below, what they need in the house.
/// Ticks are the household's, so whoever preps sees what is already done.
class LunchPrepScreen extends StatelessWidget {
  const LunchPrepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchBoardController>();
    final view = context.watch<HouseholdView>();
    final canTick = view.permissions.canEdit(HouseholdArea.lunch);
    return NestScaffold(
      title: LunchCopy.prepTitle,
      subtitle: LunchCopy.prepFor(
        NestDates.dayOfYear(
          month: controller.week.prepDay.month,
          day: controller.week.prepDay.day,
        ),
      ),
      leading: backLeading(context),
      body: NestAsyncView<LunchPrepList>(
        state: controller.prepList,
        isEmpty: (list) => list.isEmpty,
        onRetry: controller.retry,
        emptyBuilder: (context) => NestEmptyView(
          icon: Icons.soup_kitchen_outlined,
          title: LunchCopy.prepEmptyTitle,
          message: LunchCopy.prepEmptyBody,
          actionLabel: LunchCopy.backToLunches,
          onAction: () => context.canPop()
              ? context.pop()
              : context.go(LunchRoute.pathFor(view.household.id)),
        ),
        dataBuilder: (context, list) => ListView(
          padding: const EdgeInsets.only(bottom: NestSpace.huge),
          children: [
            Text(
              LunchCopy.prepProgress(list.doneCount, list.totalCount),
              style: NestTheme.of(context).text.bodySecondary,
            ),
            _PrepSection(
              title: LunchCopy.prepBatch,
              rows: list.batch,
              canTick: canTick,
            ),
            _PrepSection(
              title: LunchCopy.prepOnHand,
              rows: list.onHand,
              canTick: canTick,
            ),
          ],
        ),
      ),
    );
  }
}

/// One half of the list under its heading; nothing when it is empty.
class _PrepSection extends StatelessWidget {
  const _PrepSection({
    required this.title,
    required this.rows,
    required this.canTick,
  });

  final String title;
  final List<LunchPrepRow> rows;
  final bool canTick;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final controller = context.read<LunchBoardController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NestSpace.xl),
        NestSectionHeader(title: title),
        const SizedBox(height: NestSpace.xs),
        for (final row in rows)
          LunchPrepRowTile(
            key: ValueKey(row.item.itemId),
            row: row,
            onToggle: canTick
                ? () => controller.edit.setPrepped(
                    row.item.itemId,
                    done: !row.isDone,
                  )
                : null,
          ),
      ],
    );
  }
}
