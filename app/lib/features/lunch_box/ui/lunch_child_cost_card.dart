import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../family_profiles/model/family_entry.dart';
import '../model/lunch_week.dart';
import '../model/lunch_week_cost.dart';

/// One child's week in money: the total, then each school day's box as a
/// tag — or, with nothing packed, just that (lunch-box ADR-0007).
class LunchChildCostCard extends StatelessWidget {
  const LunchChildCostCard({
    required this.child,
    required this.cost,
    required this.week,
    super.key,
  });

  final FamilyEntry child;
  final LunchChildCost cost;
  final LunchWeek week;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final member = child.member;
    final packedDays = [
      for (final date in week.schoolDays)
        if (cost.on(date.weekday) case final day?
            when day.total.millicents > 0 || day.isAtLeast)
          (date, day),
    ];
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestAvatar(name: member.displayName, color: member.color),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LunchBudgetCopy.childWeek(member.displayName),
                      style: nest.text.caption,
                    ),
                    Text(
                      cost.isAtLeast
                          ? LunchBudgetCopy.spentAtLeast(
                              cost.total.money.display,
                            )
                          : cost.total.money.display,
                      style: nest.text.title,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          if (packedDays.isEmpty)
            Text(LunchBudgetCopy.nothingPacked, style: nest.text.bodySecondary)
          else
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final (date, day) in packedDays)
                  NestTag(
                    label: LunchBudgetCopy.dayCost(
                      NestDates.weekday(date),
                      day.total.money.display,
                    ),
                    tone: day.isAtLeast
                        ? NestTagTone.neutral
                        : NestTagTone.accent,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
