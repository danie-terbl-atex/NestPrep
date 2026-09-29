import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../calendar/ui/event_sheet.dart';
import '../../household/model/household_view.dart';
import '../model/letter_proposal.dart';
import '../model/review_item.dart';
import '../state/school_letter_controller.dart';
import 'letter_added_panel.dart';
import 'letter_reading_panel.dart';
import 'letter_review_list.dart';
import 'letter_source_panel.dart';

/// Snap a school letter (calendar ADR-0005): pick a photo or a PDF, let the
/// model read it, then tick, change and confirm what goes on the week. The
/// screen only composes; every step is its controller's.
class SchoolLetterScreen extends StatelessWidget {
  const SchoolLetterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SchoolLetterController>();
    final view = context.watch<HouseholdView>();
    final today = context.read<HouseholdClock>().today;

    return NestScaffold(
      leading: backLeading(context),
      title: SchoolLetterCopy.title,
      body: AnimatedSwitcher(
        duration: NestMotion.of(context).standard,
        child: KeyedSubtree(
          key: ValueKey(controller.step),
          child: switch (controller.step) {
            LetterStep.choosing => LetterSourcePanel(
              onPick: controller.pick,
              failure: controller.failure,
              onRetry: controller.canRetry ? controller.retry : null,
            ),
            LetterStep.reading => const LetterReadingPanel(),
            LetterStep.review || LetterStep.saving => LetterReviewList(
              items: controller.items,
              today: today,
              members: view.members,
              isSaving: controller.step == LetterStep.saving,
              callsLeft: controller.callsLeft,
              failure: controller.failure,
              onDismissFailure: controller.dismissFailure,
              onToggle: controller.toggle,
              onEdit: (item) => _edit(context, controller, item),
              onConfirm: controller.confirm,
              onStartOver: controller.startOver,
            ),
            LetterStep.done => LetterAddedPanel(
              added: controller.added,
              onSeeTheWeek: () => _toTheWeek(context, controller),
              onSnapAnother: controller.startOver,
            ),
          },
        ),
      ),
    );
  }

  /// The ordinary event sheet, filled in with the proposal — the same sheet
  /// quick add's Edit opens (calendar ADR-0004), so a changed proposal is
  /// checked by the same form as any event.
  Future<void> _edit(
    BuildContext context,
    SchoolLetterController controller,
    ReviewItem item,
  ) async {
    final view = context.read<HouseholdView>();
    final today = context.read<HouseholdClock>().today;
    final proposal = item.proposal;
    final draft = await showEventSheet(
      context: context,
      members: view.members,
      today: today,
      initialDate: proposal.date,
      draft: EventSaved(
        title: proposal.title,
        note: proposal.note,
        date: proposal.date,
        startMinute: proposal.startMinute,
        endMinute: proposal.endMinute,
        recurrence: proposal.recurrence,
        memberIds: proposal.memberIds,
      ),
    );
    if (draft is! EventSaved) return;
    controller.replace(
      item.key,
      LetterProposal(
        title: draft.title,
        note: draft.note,
        date: draft.date,
        startMinute: draft.startMinute,
        endMinute: draft.endMinute,
        recurrence: draft.recurrence,
        memberIds: draft.memberIds,
      ),
    );
  }

  /// Back to the week it was opened from, or to the week when opened by link.
  void _toTheWeek(BuildContext context, SchoolLetterController controller) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(HouseholdRoute.homeFor(controller.householdId));
    }
  }
}
