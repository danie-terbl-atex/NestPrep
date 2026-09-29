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
import '../../../shared/flags/feature_flags.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/member_filter.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../household/ui/household_link_button.dart';
import '../model/calendar_week.dart';
import '../model/quick_add/quick_add_result.dart';
import '../state/calendar_controller.dart';
import 'calendar_week_strip.dart';
import 'day_agenda.dart';
import 'event_sheet.dart';
import 'quick_add_bar.dart';
import 'quick_add_sheet.dart';

/// The family week: a strip of seven days in the household's timezone, and the
/// chosen day's agenda under it (calendar ADR-0001). The week and the member
/// filter are view state, not stored preferences.
///
/// Above the strip, quick add turns a typed line into an event the member
/// confirms (calendar ADR-0004); in the header, the way to the connected
/// calendars whose events join the week (calendar ADR-0003).
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
      // The home tab carries the brand: the small nest where a back button
      // would be on a screen that has one (design-system ADR-0003).
      leading: const NestBrandMark(width: NestSize.brandMarkSmall),
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
                  context.watch<FeatureFlags>().isOn(
                    FeatureFlag.snapSchoolLetter,
                  )) ...[
                const SizedBox(width: NestSpace.sm),
                NestIconButton(
                  icon: Icons.document_scanner_outlined,
                  label: SchoolLetterCopy.openFromWeek,
                  onPressed: () => context.push(
                    CalendarV2Route.letterPathFor(controller.householdId),
                  ),
                ),
              ],
              const SizedBox(width: NestSpace.sm),
              NestIconButton(
                icon: Icons.sync_alt,
                label: CalendarSyncCopy.openFromWeek,
                // Pushed, like the household link, so back returns here.
                onPressed: () => context.push(
                  CalendarSyncRoute.pathFor(controller.householdId),
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
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
