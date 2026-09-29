import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../model/shift_summary.dart';
import 'hub_clock.dart';
import 'summary_line.dart';

/// The last shift's summary, where the parents look first — this is the
/// handover arriving in the app, whether or not a push has been set up to
/// announce it (nanny-hub ADR-0002).
class LatestHandoverCard extends StatelessWidget {
  const LatestHandoverCard({
    required this.summary,
    required this.carer,
    required this.onOpen,
    super.key,
  });

  final ShiftSummary summary;
  final Member? carer;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final ended = summary.endedAt;
    final person = carer;
    return NestCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            NannyCopy.latestHandover,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          Row(
            children: [
              if (person != null) ...[
                NestAvatar(name: person.displayName, color: person.color),
                const SizedBox(width: NestSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NannyCopy.summaryHeadline(person?.displayName ?? ''),
                      style: nest.text.title,
                    ),
                    Text(
                      ended == null
                          ? NannyCopy.summaryPending
                          : '${clock.dayOf(ended)} · ${clock.timeOf(ended)}',
                      style: nest.text.bodySecondary,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: nest.colors.inkTertiary),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          SummaryTags(summary: summary),
        ],
      ),
    );
  }
}
