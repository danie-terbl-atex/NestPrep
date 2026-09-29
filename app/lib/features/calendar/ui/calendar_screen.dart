import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/member_filter.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../household/ui/household_link_button.dart';
import '../model/calendar_week.dart';
import '../state/calendar_controller.dart';
import 'calendar_week_strip.dart';
import 'day_agenda.dart';
import 'event_sheet.dart';

/// The family week: a strip of seven days in the household's timezone, and the
/// chosen day's agenda under it (calendar ADR-0001). The week and the member
/// filter are view state, not stored preferences.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CalendarController>();
    final view = context.read<HouseholdView>();
    final failure = controller.actionFailure;
    // Somebody who may only look at the week is not offered the button the
    // rules would refuse (household ADR-0003).
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.calendar,
    );

    return NestScaffold(
      title: AppCopy.calendarTitle,
      subtitle: NestDates.weekRange(controller.weekStart),
      trailing: const [HouseholdLinkButton(), AccountMenuButton()],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.week,
        onSelect: onSelectTab,
      ),
      floatingAction: canEdit
          ? Padding(
              padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight),
              child: NestButton(
                label: AppCopy.calendarAddEvent,
                icon: Icons.add,
                isExpanded: false,
                onPressed: () => _addEvent(context, controller, view),
              ),
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
          ),
          const SizedBox(height: NestSpace.md),
          Row(
            children: [
              Text(
                AppCopy.calendarWeekFilter,
                style: NestTheme.of(context).text.label
                    .copyWith(color: NestTheme.of(context).colors.inkSecondary),
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
              // Paging three weeks out and back again is the long way home.
              // The way back only exists when there is somewhere to go.
              if (controller.weekStart != controller.today.weekStart) ...[
                const SizedBox(width: NestSpace.sm),
                NestButton(
                  label: AppCopy.calendarThisWeek,
                  variant: NestButtonVariant.ghost,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: controller.goToThisWeek,
                ),
              ],
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Expanded(
            child: NestAsyncView<CalendarWeek>(
              state: controller.week,
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (_, week) => DayAgenda(
                week: week,
                day: controller.selectedDay,
                householdId: controller.householdId,
              ),
            ),
          ),
        ],
      ),
    );
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
