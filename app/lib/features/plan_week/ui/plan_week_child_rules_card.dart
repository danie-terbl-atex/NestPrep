import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/family_entry.dart';

/// One chosen child in the brief: what NestPrep will keep out of their box —
/// their allergies, the nut rule and why, what they will not eat — and what
/// they like, read from their family profile (lunch-box ADR-0012 §1.1).
class PlanWeekChildRulesCard extends StatelessWidget {
  const PlanWeekChildRulesCard({required this.child, super.key});

  final FamilyEntry child;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final rules = child.foodRules;
    final keptOut = [
      for (final allergy in rules.allergies)
        switch (allergy.allergen) {
          final allergen? => FamilyCopy.allergenName(allergen),
          null => allergy.otherName ?? '',
        },
      if (rules.isNutFree) LunchCopy.nutRule(rules.nutFreeReasons),
      ...rules.dislikes,
    ].where((thing) => thing.isNotEmpty).toList();
    final member = child.member;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NestAvatar(name: member.displayName, color: member.color),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName, style: nest.text.title),
                const SizedBox(height: NestSpace.xs),
                Text(
                  keptOut.isEmpty
                      ? PlanWeekCopy.nothingKeptOut
                      : PlanWeekCopy.keptOut(keptOut.join(', ')),
                  style: nest.text.body,
                ),
                if (rules.likes.isNotEmpty)
                  Text(
                    PlanWeekCopy.likes(rules.likes.join(', ')),
                    style: nest.text.bodySecondary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
