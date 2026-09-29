import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_planning_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/back_leading.dart';
import '../../family_profiles/ui/sheet_outcome.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../model/lunch_board.dart';
import '../model/lunch_choices.dart';
import '../model/lunch_day.dart';
import '../model/lunch_slot.dart';
import '../state/lunch_board_controller.dart';
import '../state/lunch_choices_controller.dart';
import 'lunch_child_switcher.dart';
import 'lunch_kid_picks_day_card.dart';
import 'lunch_options_sheet.dart';

/// A parent's side of kid picks (lunch-box ADR-0008): for the child whose
/// week is open, two or three options per compartment for each day from
/// today, then *Let them choose* — on this phone, or waiting on their
/// tablet.
class LunchKidPicksScreen extends StatelessWidget {
  const LunchKidPicksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lunch = context.watch<LunchBoardController>();
    final picks = context.watch<LunchChoicesController>();
    final failure = picks.actionFailure ?? lunch.actionFailure;
    return NestScaffold(
      title: LunchKidPicksCopy.title,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: () {
                  picks.dismissActionFailure();
                  lunch.dismissActionFailure();
                },
              ),
            ),
          Expanded(
            child: NestAsyncView<Map<String, LunchChoices>>(
              state: picks.choices,
              // The days are the view in every state: each compartment is
              // the way to its options (`FE-08`).
              isEmpty: (_) => false,
              onRetry: picks.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              // The choices publish only once the board has, so the board is
              // here whenever they are.
              dataBuilder: (context, _) => switch (lunch.board) {
                AsyncData(:final value) => _PicksBody(board: value),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PicksBody extends StatelessWidget {
  const _PicksBody({required this.board});

  final LunchBoard board;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final lunch = context.watch<LunchBoardController>();
    final picks = context.watch<LunchChoicesController>();
    final view = context.watch<HouseholdView>();
    final canEdit = view.permissions.canEdit(HouseholdArea.lunch);
    final childWeek =
        board.childWeek(lunch.selectedChildId ?? '') ??
        board.children.firstOrNull;
    if (childWeek == null) {
      return const NestEmptyView(
        icon: Icons.bento_outlined,
        title: LunchCopy.noChildrenTitle,
        message: LunchCopy.noChildrenBody,
      );
    }
    final name = childWeek.child.member.displayName;
    final choices = picks.choicesFor(childWeek.childId, board.week);
    final days = [
      for (final day in childWeek.days)
        if (!day.date.isBefore(board.today)) day,
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        LunchChildSwitcher(
          children: board.children,
          selectedChildId: childWeek.childId,
          onSelect: lunch.selectChild,
        ),
        const SizedBox(height: NestSpace.md),
        NestRiseIn(
          child: NestCard(
            variant: NestCardVariant.tinted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(LunchKidPicksCopy.subtitle(name), style: nest.text.title),
                const SizedBox(height: NestSpace.xs),
                Text(LunchKidPicksCopy.introBody, style: nest.text.body),
                if (canEdit && days.isNotEmpty) ...[
                  const SizedBox(height: NestSpace.md),
                  NestButton(
                    label: LunchKidPicksCopy.suggestOptions,
                    icon: Icons.auto_awesome_rounded,
                    variant: NestButtonVariant.tonal,
                    isLoading: picks.isSuggesting,
                    onPressed: () => picks.suggestWeek(childWeek),
                  ),
                ],
                if (!choices.isEmpty && days.isNotEmpty) ...[
                  const SizedBox(height: NestSpace.sm),
                  NestButton(
                    label: LunchKidPicksCopy.letChoose(name),
                    icon: Icons.touch_app_rounded,
                    onPressed: () => context.push(
                      LunchPlanningRoute.choosePathFor(
                        view.household.id,
                        childWeek.childId,
                      ),
                    ),
                  ),
                  const SizedBox(height: NestSpace.sm),
                  Text(LunchKidPicksCopy.tabletHint, style: nest.text.caption),
                ],
              ],
            ),
          ),
        ),
        if (days.isEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          Text(LunchKidPicksCopy.weekOver, style: nest.text.bodySecondary),
        ],
        for (final (index, day) in days.indexed) ...[
          const SizedBox(height: NestSpace.md),
          NestRiseIn(
            index: index + 1,
            child: LunchKidPicksDayCard(
              key: ValueKey('${childWeek.childId}-${day.date.iso}'),
              day: day,
              choices: choices,
              childName: name,
              onSlot: canEdit
                  ? (slot) => _setOptions(context, childWeek, day, slot)
                  : null,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _setOptions(
    BuildContext context,
    LunchChildWeek childWeek,
    LunchDay day,
    LunchSlot slot,
  ) async {
    final picks = context.read<LunchChoicesController>();
    final weekday = day.date.weekday;
    final outcome = await showLunchOptionsSheet(
      context: context,
      slot: slot,
      dayName: NestDates.weekdayName(day.date),
      ranked: childWeek.rank(slot, board.library),
      current: picks
          .choicesFor(childWeek.childId, board.week)
          .optionsAt(weekday, slot),
    );
    switch (outcome) {
      case null:
        return;
      case SheetSaved(:final value):
        await picks.setOptions(
          childWeek: childWeek,
          isoWeekday: weekday,
          slot: slot,
          items: value,
        );
      case SheetRemoved():
        await picks.clearOptions(
          childId: childWeek.childId,
          isoWeekday: weekday,
          slot: slot,
        );
    }
  }
}
