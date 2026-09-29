import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/handover_entry.dart';
import '../model/handover_kind.dart';
import '../model/nanny_hub_view.dart';
import '../model/photo_change.dart';
import '../model/shift.dart';
import '../model/shift_log.dart';
import '../state/nanny_hub_controller.dart';
import '../state/shift_controller.dart';
import 'end_shift_sheet.dart';
import 'handover_timeline.dart';
import 'log_entry_sheet.dart';
import 'quick_log_grid.dart';
import 'shift_checklist_panel.dart';
import 'shift_header.dart';

/// Everything shift mode shows once the shift and the hub have loaded.
class ShiftBody extends StatelessWidget {
  const ShiftBody({
    required this.log,
    required this.view,
    required this.shift,
    required this.hub,
    super.key,
  });

  final ShiftLog log;
  final NannyHubView view;
  final ShiftController shift;
  final NannyHubController hub;

  Future<void> _log(BuildContext context, HandoverKind kind) async {
    final outcome = await showLogEntrySheet(
      context: context,
      kind: kind,
      children: [for (final child in view.children) child.member],
      clock: context.read<HouseholdClock>(),
      onPick: hub.pickPhoto,
    );
    if (outcome == null) return;
    await shift.addEntry(
      outcome.draft,
      photo: switch (outcome.photo) {
        PhotoPicked(:final bytes) => bytes,
        _ => null,
      },
    );
  }

  Future<void> _edit(BuildContext context, HandoverEntry entry) async {
    final outcome = await showLogEntrySheet(
      context: context,
      kind: entry.kind,
      children: [for (final child in view.children) child.member],
      clock: context.read<HouseholdClock>(),
      onPick: hub.pickPhoto,
      existing: entry,
    );
    if (outcome == null) return;
    if (outcome.isRemoval) {
      await shift.removeEntry(entry);
    } else {
      await shift.updateEntry(entry, outcome.draft, photo: outcome.photo);
    }
  }

  Future<void> _end(BuildContext context, Shift current) async {
    final note = await showEndShiftSheet(context: context);
    if (note == null) return;
    final ended = await shift.end(closingNote: note);
    if (!ended || !context.mounted) return;
    context.pushReplacement(
      NannyHubRoute.summaryPathFor(hub.householdId, current.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = log.shift!;
    final access = hub.access;
    final isOpen = current.isOpen;
    final canLog = isOpen && access.canEdit;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        ShiftHeader(
          shift: current,
          carer: hub.memberById(current.carerMemberId),
          children: [for (final child in view.children) child.member],
        ),
        const SizedBox(height: NestSpace.xl),
        if (!isOpen) ...[
          NestCard(
            variant: NestCardVariant.tinted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  NannyCopy.shiftEndedTitle,
                  style: NestTheme.of(context).text.title,
                ),
                Text(
                  NannyCopy.shiftEndedBody,
                  style: NestTheme.of(context).text.bodySecondary,
                ),
                const SizedBox(height: NestSpace.lg),
                NestButton(
                  label: NannyCopy.seeSummary,
                  onPressed: () => context.pushReplacement(
                    NannyHubRoute.summaryPathFor(hub.householdId, current.id),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpace.xl),
        ],
        if (canLog) ...[
          QuickLogGrid(
            isBusy: shift.isSaving,
            onLog: (kind) => _log(context, kind),
          ),
          const SizedBox(height: NestSpace.xl),
        ],
        ShiftChecklistPanel(
          checklists: view.hub.checklists,
          shift: current,
          canTick: canLog,
          onTick: (moment, itemId, isTicked) =>
              shift.setTick(moment, itemId, isTicked: isTicked),
        ),
        const SizedBox(height: NestSpace.xl),
        HandoverTimeline(
          entries: log.newestFirst,
          children: [for (final child in view.children) child.member],
          canEdit: (entry) => canLog && shift.isMine(entry),
          onEdit: (entry) => _edit(context, entry),
        ),
        if (isOpen && access.mayEndShiftOf(current.carerMemberId)) ...[
          const SizedBox(height: NestSpace.xxxl),
          NestButton(
            label: NannyCopy.endShift,
            variant: NestButtonVariant.outline,
            icon: Icons.nights_stay_outlined,
            isLoading: shift.isEnding,
            onPressed: shift.isEnding ? null : () => _end(context, current),
          ),
        ],
      ],
    );
  }
}
