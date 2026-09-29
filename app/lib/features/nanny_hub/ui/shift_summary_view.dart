import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../model/shift_summary.dart';
import 'hub_clock.dart';
import 'summary_line.dart';
import 'summary_moment_row.dart';

/// Everything a summary says, in the order a parent wants it: whose shift and
/// when, anything that went wrong, the counts, the carer's last word, the
/// checklists, and then the evening moment by moment.
class ShiftSummaryView extends StatelessWidget {
  const ShiftSummaryView({
    required this.summary,
    required this.memberById,
    super.key,
  });

  final ShiftSummary summary;
  final Member? Function(String memberId) memberById;

  String _when(HouseholdClock clock) {
    final started = summary.startedAt;
    final ended = summary.endedAt;
    if (started == null || ended == null) return NannyShiftCopy.summaryPending;
    return NannyShiftCopy.summaryWhen(
      clock.dayOf(ended),
      clock.timeOf(started),
      clock.timeOf(ended),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final carer = memberById(summary.carerMemberId);
    final closing = summary.closingNote;
    final checklist = summary.checklist;
    final label = nest.text.label.copyWith(color: nest.colors.inkSecondary);
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Row(
          children: [
            if (carer != null) ...[
              NestAvatar(
                name: carer.displayName,
                color: carer.color,
                size: NestSize.avatarLarge,
              ),
              const SizedBox(width: NestSpace.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    NannyShiftCopy.summaryHeadline(carer?.displayName ?? ''),
                    style: nest.text.headline,
                  ),
                  Text(_when(clock), style: nest.text.bodySecondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: NestSpace.lg),
        if (summary.hadIncident) ...[
          const NestBanner(
            message: NannyShiftCopy.summaryIncident,
            tone: NestBannerTone.warning,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        SummaryTags(summary: summary),
        if (closing != null) ...[
          const SizedBox(height: NestSpace.xl),
          NestCard(
            variant: NestCardVariant.tinted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(NannyShiftCopy.summaryClosingNote, style: label),
                const SizedBox(height: NestSpace.xs),
                Text(closing, style: nest.text.body),
              ],
            ),
          ),
        ],
        if (!checklist.isEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          Text(NannyShiftCopy.summaryChecklist, style: label),
          const SizedBox(height: NestSpace.xs),
          Text(
            NannyShiftCopy.ticked(checklist.ticked, checklist.total),
            style: nest.text.bodyStrong,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        Text(NannyShiftCopy.summaryMoments, style: nest.text.title),
        const SizedBox(height: NestSpace.sm),
        if (summary.moments.isEmpty)
          Text(
            NannyShiftCopy.summaryNothingLogged,
            style: nest.text.bodySecondary,
          ),
        for (final (index, moment) in summary.moments.indexed)
          Padding(
            key: ValueKey(index),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: SummaryMomentRow(
              moment: moment,
              childNames: [
                for (final id in moment.childIds) ?memberById(id)?.displayName,
              ],
            ),
          ),
        if (summary.isTrimmed)
          Text(
            NannyShiftCopy.summaryTrimmed(summary.moments.length),
            style: nest.text.caption,
          ),
      ],
    );
  }
}
