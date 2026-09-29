import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/time/household_clock.dart';
import '../data/photo_picker.dart';
import '../model/handover_entry.dart';
import '../model/handover_kind.dart';
import '../model/nanny_hub_view.dart';
import '../model/photo_change.dart';
import '../model/shift.dart';
import '../model/shift_log.dart';
import '../state/nanny_hub_controller.dart';
import '../state/photo_feed_controller.dart';
import '../state/shift_controller.dart';
import 'end_shift_sheet.dart';
import 'handover_timeline.dart';
import 'log_entry_sheet.dart';
import 'photo_update_sheet.dart';
import 'quick_log_grid.dart';
import 'send_photo_card.dart';
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

  /// A photo for the parents, straight from the camera or the library: picked,
  /// captioned, sent (nanny-hub ADR-0004).
  Future<void> _sendPhoto(
    BuildContext context,
    PhotoFeedController feed,
    PhotoSource source,
  ) async {
    final photo = await hub.pickPhoto(source);
    if (photo == null || !context.mounted) return;
    final choice = await showPhotoUpdateSheet(
      context: context,
      photo: photo,
      children: [for (final child in view.children) child.member],
    );
    if (choice == null) return;
    await feed.send(photo, caption: choice.caption, childIds: choice.childIds);
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
    final feed = context.watch<PhotoFeedController>();
    final sendsPhotos =
        canLog &&
        context.watch<FeatureFlagsController>().isOn(
          FeatureFlag.nannyPhotoUpdates,
        );
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
                  NannyShiftCopy.shiftEndedTitle,
                  style: NestTheme.of(context).text.title,
                ),
                Text(
                  NannyShiftCopy.shiftEndedBody,
                  style: NestTheme.of(context).text.bodySecondary,
                ),
                const SizedBox(height: NestSpace.lg),
                NestButton(
                  label: NannyShiftCopy.seeSummary,
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
        // After the log, which comes first in shift mode (nanny-hub ADR-0002):
        // a photo for the parents (ADR-0004).
        if (sendsPhotos) ...[
          SendPhotoCard(
            sentCount: switch (feed.feed) {
              AsyncData(:final value) => value.updates.length,
              _ => 0,
            },
            isSending: feed.isSending,
            onPick: (source) => _sendPhoto(context, feed, source),
            onOpenFeed: () => context.push(
              NannyHubRoute.photosPathFor(hub.householdId, current.id),
            ),
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
            label: NannyShiftCopy.endShift,
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
