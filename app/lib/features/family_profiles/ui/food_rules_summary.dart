import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/allergy_severity.dart';
import '../model/food_rules.dart';
import 'allergy_names.dart';

/// The rules a person's food is bound by, said before anything else on their
/// profile: a severe allergy as a danger banner naming it, and nut-free with
/// every reason it holds. Nothing at all when nothing applies.
class FoodRulesSummary extends StatelessWidget {
  const FoodRulesSummary({required this.rules, super.key});

  final FoodRules rules;

  @override
  Widget build(BuildContext context) {
    final severe = [
      for (final allergy in rules.allergies)
        if (allergy.severity == AllergySeverity.severe) allergyName(allergy),
    ];
    final reasons = rules.nutFreeReasons;
    if (severe.isEmpty && reasons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (severe.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestBanner(
              message: FamilyCopy.severeWarning(severe),
              tone: NestBannerTone.danger,
            ),
          ),
        // A banner rather than a tag: it wraps, and a safety rule truncated
        // to "Nut-free · nut allergy,…" at 200% text has lost the part that
        // says why (`FE-13`).
        if (reasons.isNotEmpty)
          NestBanner(
            message: FamilyCopy.nutFreeBecause(
              NutFreeReason.values.where(reasons.contains),
            ),
            tone: NestBannerTone.warning,
          ),
      ],
    );
  }
}
