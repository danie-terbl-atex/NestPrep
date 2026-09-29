import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../model/shift_summary.dart';
import 'hub_clock.dart';

/// Every shift's summary, newest first, kept for the parents. When there are
/// none yet it says what will appear here, in place (`FE-08`).
class PastShifts extends StatelessWidget {
  const PastShifts({
    required this.summaries,
    required this.memberById,
    required this.onOpen,
    super.key,
  });

  final List<ShiftSummary> summaries;
  final Member? Function(String memberId) memberById;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: NannyCopy.pastShifts),
        const SizedBox(height: NestSpace.sm),
        if (summaries.isEmpty)
          Text(
            NannyCopy.noPastShifts,
            style: nest.text.bodySecondary.copyWith(
              color: nest.colors.inkTertiary,
            ),
          ),
        for (final summary in summaries)
          Padding(
            key: ValueKey(summary.shiftId),
            padding: const EdgeInsets.only(bottom: NestSpace.xs),
            child: NestListRow(
              leading: switch (memberById(summary.carerMemberId)) {
                final Member carer => NestAvatar(
                  name: carer.displayName,
                  color: carer.color,
                  size: NestSize.avatarSmall,
                ),
                null => const Icon(Icons.history),
              },
              title: NannyCopy.summaryHeadline(
                memberById(summary.carerMemberId)?.displayName ?? '',
              ),
              subtitle: _when(clock, summary),
              trailing: summary.hadIncident
                  ? Icon(Icons.healing_outlined, color: nest.colors.danger)
                  : const Icon(Icons.chevron_right),
              onTap: () => onOpen(summary.shiftId),
            ),
          ),
      ],
    );
  }

  static String _when(HouseholdClock clock, ShiftSummary summary) {
    final ended = summary.endedAt;
    return ended == null
        ? NannyCopy.summaryPending
        : '${clock.dayOf(ended)} · ${clock.timeOf(ended)}';
  }
}
