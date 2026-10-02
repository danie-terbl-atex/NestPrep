import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/family_entry.dart';
import 'allergy_names.dart';
import 'severity_look.dart';

/// One person on the family list: who they are, where they go to school, and
/// — before anything else can be missed — their allergies in their severity's
/// tone and whether they are nut-free.
class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    required this.entry,
    required this.age,
    required this.onTap,
    super.key,
  });

  final FamilyEntry entry;
  final int? age;
  final VoidCallback onTap;

  /// Enough to recognise the child at a glance; the rest is one tap away.
  static const shownAllergies = 3;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final member = entry.member;
    final rules = entry.foodRules;
    final years = age;
    final details = [
      if (years != null) FamilyCopy.age(years),
      ?entry.school?.name,
      ?entry.profile.grade,
    ];
    final extraAllergies = rules.allergies.length - shownAllergies;
    final tags = [
      for (final allergy in rules.allergies.take(shownAllergies))
        NestTag(
          label: allergyName(allergy),
          tone: allergy.severity.tone,
          icon: allergy.severity.icon,
        ),
      if (extraAllergies > 0)
        NestTag(label: FamilyCopy.moreAllergies(extraAllergies)),
      if (rules.isNutFree)
        const NestTag(
          label: FamilyCopy.nutFree,
          tone: NestTagTone.warning,
          icon: LucideIcons.utensilsCrossed,
        ),
    ];
    return NestCard(
      onTap: onTap,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestAvatar(
                name: member.displayName,
                color: member.color,
                size: NestSize.avatarLarge,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.displayName, style: nest.text.title),
                    Text(
                      details.isEmpty
                          ? FamilyCopy.nothingRecorded
                          : details.join(' · '),
                      style: nest.text.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: NestSize.iconMedium,
                color: nest.colors.inkTertiary,
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: NestSpace.md),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: tags,
            ),
          ],
        ],
      ),
    );
  }
}
