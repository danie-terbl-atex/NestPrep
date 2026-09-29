import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
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
    return NannyHubPage(
      title: NannyCopy.summaryTitle,
      // Opened a moment after the end, the summary may not have reached the
      // listener yet; said, rather than shown as blank.
      isEmpty: (view) => view.hub.summaryOf(shiftId) == null,
      emptyBuilder: (_) => const NestEmptyView(
        title: NannyCopy.summaryGoneTitle,
        message: NannyCopy.summaryGoneBody,
        icon: Icons.hourglass_empty,
      ),
      builder: (context, view) => ShiftSummaryView(
        summary: view.hub.summaryOf(shiftId)!,
        memberById: controller.memberById,
      ),
    );
  }
}
