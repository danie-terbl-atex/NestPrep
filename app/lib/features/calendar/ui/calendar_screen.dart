import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/calendar_sync_route.dart';
import '../../../app/calendar_v2_route.dart';
import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/member_filter.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../notifications/ui/notification_bell.dart';
import '../../two_homes/ui/custody_day_bands.dart';
import '../../two_homes/ui/custody_day_mark.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import '../model/calendar_view.dart';
import '../model/calendar_week.dart';
import '../model/quick_add/quick_add_result.dart';
import '../state/calendar_controller.dart';
import 'calendar_month_grid.dart';
import 'calendar_week_strip.dart';
import 'day_agenda.dart';
import 'entry_colors.dart';
import 'event_sheet.dart';
import 'quick_add_bar.dart';
import 'quick_add_sheet.dart';

/// The family calendar, a tab of its own (design-system ADR-0017): a month
/// grid, where it opens, or the week strip, and the chosen day's agenda under
/// either, all in the household's timezone (calendar ADR-0001). The view, the
/// window and the member filter are view state, not stored preferences.
///
/// Above them, quick add turns a typed line into an event the member confirms
/// (calendar ADR-0004), beside the way to the connected calendars whose events
/// join it (calendar ADR-0003).
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CalendarController>();
    final view = context.read<HouseholdView>();
    final failure = controller.actionFailure;
    // Somebody who may only look at the calendar is not offered the button
    // the rules would refuse (household ADR-0003).
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.calendar,
    );
    final isMonth = controller.view == CalendarView.month;

    return NestScaffold(
      title: AppCopy.calendarTitle,
      subtitle: isMonth ? null : NestDates.weekRange(controller.weekStart),
      trailing: const [NotificationBell(), AccountMenuButton()],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.week,
        onSelect: onSelectTab,
      ),
      floatingAction: canEdit
          ? NestButton(
              label: AppCopy.calendarAddEvent,
              icon: LucideIcons.plus,
              isExpanded: false,
              onPressed: () => _addEvent(context, controller, view),
            )
          : null,
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
                onAction: controller.dismissActionFailure,
              ),
            ),
          TourAnchor(
            target: TourTarget.calendarViews,
            child: NestSegmentedControl<CalendarView>(
              segments: const [
                NestSegment(
                  value: CalendarView.month,
                  label: AppCopy.calendarMonth,
                  icon: LucideIcons.calendarDays,
                ),
                NestSegment(
                  value: CalendarView.week,
                  label: AppCopy.calendarWeek,
                  icon: LucideIcons.calendarRange,
                ),
              ],
              selected: controller.view,
              onSelect: controller.showView,
            ),
          ),
          const SizedBox(height: NestSpace.md),
          // Beside quick add rather than in the header, which at 200% text
          // has no room for a third button on a 360-wide phone (`FE-14`).
          Row(
            children: [
              Expanded(
                child: QuickAddBar(
                  onOpen: () => _quickAdd(context, controller, view),
                ),
              ),
              // calendar V2: snap a school letter (calendar ADR-0005) — for
              // somebody who may add events, while its switch is on.
              if (canEdit &&
                  context.watch<FeatureFlagsController>().isOn(
                    FeatureFlag.snapSchoolLetter,
                  )) ...[
                const SizedBox(width: NestSpace.sm),
                NestIconButton(
                  icon: LucideIcons.scanText,
                  label: SchoolLetterCopy.openFromWeek,
                  onPressed: () => context.push(
                    CalendarV2Route.letterPathFor(controller.householdId),
                  ),
                ),
              ],
              const SizedBox(width: NestSpace.sm),
              NestIconButton(
                icon: LucideIcons.arrowRightLeft,
                label: CalendarSyncCopy.openFromWeek,
                // Pushed, like the household link, so back returns here.
                onPressed: () => context.push(
                  CalendarSyncRoute.pathFor(controller.householdId),
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Expanded(
            child: isMonth
                ? _MonthBody(controller: controller, view: view)
                : _WeekBody(controller: controller, view: view),
          ),
        ],
      ),
    );
  }

  /// Quick add proposes; the member confirms, or opens the full sheet with it
  /// filled in (calendar ADR-0004). Either way the save is the controller's.
  Future<void> _quickAdd(
    BuildContext context,
    CalendarController controller,
    HouseholdView view,
  ) async {
    final choice = await showQuickAddSheet(
      context: context,
      today: controller.today,
      members: view.members,
    );
    if (!context.mounted) return;
    switch (choice) {
      case null:
        return;
      case QuickAddConfirmed(:final proposal):
        await controller.saveEvent(
          title: proposal.title,
          date: proposal.date,
          startMinute: proposal.startMinute,
          endMinute: proposal.endMinute,
          recurrence: proposal.recurrence,
          memberIds: proposal.memberIds,
        );
        controller.showDay(proposal.date);
      case QuickAddToEdit(:final proposal):
        await _editProposal(context, controller, view, proposal);
    }
  }

  Future<void> _editProposal(
    BuildContext context,
    CalendarController controller,
    HouseholdView view,
    QuickAddProposal proposal,
  ) async {
    final draft = await showEventSheet(
      context: context,
      members: view.members,
      today: controller.today,
      initialDate: proposal.date,
      draft: EventSaved(
        title: proposal.title,
        date: proposal.date,
        startMinute: proposal.startMinute,
        endMinute: proposal.endMinute,
        recurrence: proposal.recurrence,
        memberIds: proposal.memberIds,
      ),
    );
    if (draft is! EventSaved) return;
    await controller.saveEvent(
      title: draft.title,
      note: draft.note,
      date: draft.date,
      startMinute: draft.startMinute,
      endMinute: draft.endMinute,
      recurrence: draft.recurrence,
      memberIds: draft.memberIds,
    );
    controller.showDay(draft.date);
  }

  Future<void> _addEvent(
    BuildContext context,
    CalendarController controller,
    HouseholdView view,
  ) async {
    final draft = await showEventSheet(
      context: context,
      members: view.members,
      today: controller.today,
      initialDate: controller.selectedDay,
    );
    if (draft is! EventSaved) return;
    await controller.saveEvent(
      title: draft.title,
      note: draft.note,
      date: draft.date,
      startMinute: draft.startMinute,
      endMinute: draft.endMinute,
      recurrence: draft.recurrence,
      memberIds: draft.memberIds,
    );
  }
}

/// The month grid and, under it in the same scroll, the chosen day — so at
/// 200% text the day scrolls into reach instead of being squeezed off the
/// screen (`FE-14`).
class _MonthBody extends StatelessWidget {
  const _MonthBody({required this.controller, required this.view});

  final CalendarController controller;
  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    final day = controller.selectedDay;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
        CalendarMonthGrid(
          month: controller.month,
          today: controller.today,
          selected: day,
          // Drawn from the month being looked at, which is known the moment
          // it changes, so paging never collapses the grid (`FE-08`).
          dotsByDay: switch (controller.week) {
            AsyncData(value: final week) => _dotsOf(week, view),
            _ => const {},
          },
          onSelect: controller.showDay,
          onPrevious: controller.goToPreviousMonth,
          onNext: controller.goToNextMonth,
        ),
        const SizedBox(height: NestSpace.md),
        _FilterRow(
          controller: controller,
          view: view,
          backLabel: AppCopy.calendarThisMonth,
          isAway: !controller.month.contains(controller.today),
          onBack: controller.goToThisMonth,
        ),
        const SizedBox(height: NestSpace.lg),
        NestAsyncView<CalendarWeek>(
          state: controller.week,
          isEmpty: (_) => false,
          onRetry: controller.retry,
          emptyBuilder: (_) => const SizedBox.shrink(),
          dataBuilder: (context, week) => DayAgenda(
            week: week,
            day: day,
            householdId: controller.householdId,
            isScrollable: false,
            lead: CustodyDayBands.showsOn(context, day)
                ? CustodyDayBands(day: day)
                : null,
          ),
        ),
      ],
    );
  }

  /// Whose colours are on each day, in the day's own order, once each.
  static Map<String, DayDots> _dotsOf(CalendarWeek week, HouseholdView view) {
    final dots = <String, DayDots>{};
    for (final day in week.days) {
      final entries = week.on(day);
      if (entries.isEmpty) continue;
      final colors = <MemberColor?>{};
      for (final entry in entries) {
        final own = entryColors(entry, view);
        if (own.isEmpty) colors.add(null);
        colors.addAll(own);
      }
      dots[day.iso] = (count: entries.length, colors: colors.toList());
    }
    return dots;
  }
}

/// The week strip and the chosen day's agenda (calendar phase 1).
class _WeekBody extends StatelessWidget {
  const _WeekBody({required this.controller, required this.view});

  final CalendarController controller;
  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The strip is drawn from the week being looked at, which is known
        // the moment it changes — so paging a week never collapses the
        // screen into a skeleton (`FE-08`).
        CalendarWeekStrip(
          weekStart: controller.weekStart,
          today: controller.today,
          selected: controller.selectedDay,
          daysWithEvents: switch (controller.week) {
            AsyncData(value: final week) => {
              for (final day in week.days)
                if (week.on(day).isNotEmpty) day.iso,
            },
            _ => const <String>{},
          },
          onSelect: controller.selectDay,
          onPrevious: controller.goToPreviousWeek,
          onNext: controller.goToNextWeek,
          // co-parenting: which home each linked child is with (household
          // ADR-0004). Draws nothing when two homes is off.
          dayFooter: (day) => CustodyDayMark(day: day),
        ),
        const SizedBox(height: NestSpace.md),
        _FilterRow(
          controller: controller,
          view: view,
          backLabel: AppCopy.calendarThisWeek,
          isAway: controller.weekStart != controller.today.weekStart,
          onBack: controller.goToThisWeek,
        ),
        const SizedBox(height: NestSpace.md),
        Expanded(
          child: NestAsyncView<CalendarWeek>(
            state: controller.week,
            isEmpty: (_) => false,
            onRetry: controller.retry,
            emptyBuilder: (_) => const SizedBox.shrink(),
            dataBuilder: (context, week) => DayAgenda(
              week: week,
              day: controller.selectedDay,
              householdId: controller.householdId,
              // co-parenting: the linked children's all-day bands, at the
              // top of the day (household ADR-0004). None when there are
              // none, or when two homes is off.
              lead: CustodyDayBands.showsOn(context, controller.selectedDay)
                  ? CustodyDayBands(day: controller.selectedDay)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Whose events are showing, and — only when there is somewhere to go — the
/// way back to now, because paging three weeks out and back again is the
/// long way home.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.controller,
    required this.view,
    required this.backLabel,
    required this.isAway,
    required this.onBack,
  });

  final CalendarController controller;
  final HouseholdView view;
  final String backLabel;
  final bool isAway;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Row(
      children: [
        Text(
          AppCopy.calendarWeekFilter,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(width: NestSpace.sm),
        Expanded(
          child: MemberFilter(
            members: view.members,
            selectedId: controller.memberFilter,
            onSelect: controller.filterBy,
            everybodyLabel: AppCopy.calendarEveryone,
          ),
        ),
        if (isAway) ...[
          const SizedBox(width: NestSpace.sm),
          NestButton(
            label: backLabel,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: onBack,
          ),
        ],
      ],
    );
  }
}
