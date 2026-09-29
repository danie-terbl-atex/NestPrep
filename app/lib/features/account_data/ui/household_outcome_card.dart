import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/deletion_preview.dart';

/// What deleting does to one household, in a sentence, with its weight shown
/// by more than colour: the icon and the words carry it, and a household that
/// ends says how to keep it going instead (`FE-13`, accounts ADR-0006).
class HouseholdOutcomeCard extends StatelessWidget {
  const HouseholdOutcomeCard({required this.household, super.key});

  final HouseholdDeletionPreview household;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ends = household.outcome == HouseholdDeletionOutcome.end;
    final (icon, tint) = switch (household.outcome) {
      HouseholdDeletionOutcome.leave => (Icons.logout, NestTileTint.sky),
      HouseholdDeletionOutcome.handOver => (
        Icons.swap_horiz,
        NestTileTint.mint,
      ),
      HouseholdDeletionOutcome.end => (
        Icons.delete_forever_outlined,
        NestTileTint.pink,
      ),
    };
    return NestCard(
      variant: ends ? NestCardVariant.raised : NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NestIconTile(
                icon: icon,
                tint: tint,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(household.name, style: nest.text.title),
                    const SizedBox(height: NestSpace.xs),
                    Text(_sentence(), style: nest.text.body),
                  ],
                ),
              ),
            ],
          ),
          if (ends) ...[
            const SizedBox(height: NestSpace.md),
            NestBanner(
              message: household.hasPremium
                  ? '${AccountDataCopy.outcomeEndHint} '
                        '${AccountDataCopy.outcomePremiumEnds}'
                  : AccountDataCopy.outcomeEndHint,
              tone: NestBannerTone.warning,
            ),
          ],
        ],
      ),
    );
  }

  String _sentence() => switch (household.outcome) {
    HouseholdDeletionOutcome.leave => AccountDataCopy.outcomeLeave(
      household.name,
    ),
    HouseholdDeletionOutcome.handOver => AccountDataCopy.outcomeHandOver(
      household.name,
      household.successorName ?? '',
    ),
    HouseholdDeletionOutcome.end => AccountDataCopy.outcomeEnd(
      household.name,
      household.othersLosingAccess,
    ),
  };
}
