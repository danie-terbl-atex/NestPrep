import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../state/nanny_hub_controller.dart';
import 'nanny_hub_page.dart';
import 'shift_summary_view.dart';

/// One shift's handover, as `endNannyShift` wrote it for the parents: who,
/// when, what happened in counts and in order, an incident called out first,
/// the checklists, and the carer's last word (nanny-hub ADR-0002).
class ShiftSummaryScreen extends StatelessWidget {
  const ShiftSummaryScreen({required this.shiftId, super.key});

  final String shiftId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NannyHubController>();
    final showsPhotos = context.watch<FeatureFlagsController>().isOn(
      FeatureFlag.nannyPhotoUpdates,
    );
    return NannyHubPage(
      title: NannyShiftCopy.summaryTitle,
      // The photos sent during the shift stay with it (nanny-hub ADR-0004).
      trailing: [
        if (showsPhotos)
          NestIconButton(
            icon: LucideIcons.images,
            label: NannyPhotoCopy.shiftPhotos,
            onPressed: () => context.push(
              NannyHubRoute.photosPathFor(controller.householdId, shiftId),
            ),
          ),
      ],
      // Opened a moment after the end, the summary may not have reached the
      // listener yet; said, rather than shown as blank.
      isEmpty: (view) => view.hub.summaryOf(shiftId) == null,
      emptyBuilder: (_) => const NestEmptyView(
        title: NannyShiftCopy.summaryGoneTitle,
        message: NannyShiftCopy.summaryGoneBody,
        icon: LucideIcons.hourglass,
      ),
      builder: (context, view) => ShiftSummaryView(
        summary: view.hub.summaryOf(shiftId)!,
        memberById: controller.memberById,
      ),
    );
  }
}
