import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/allergy.dart';
import 'allergy_names.dart';
import 'family_section_card.dart';
import 'family_section_empty.dart';
import 'health_lock.dart';
import 'severity_look.dart';

/// A person's allergies, most dangerous first, each in its severity's tone
/// with the severity named beside it. Tapping one edits it; the corner adds
/// one. Both are absent for somebody who may not change this profile.
///
/// Locked, for a household without Premium, it shows no allergy at all and
/// its corner is the way to the paywall (subscriptions ADR-0008).
class AllergySection extends StatelessWidget {
  const AllergySection({
    required this.allergies,
    required this.onAdd,
    required this.onEdit,
    this.isLocked = false,
    super.key,
  });

  final List<Allergy> allergies;
  final bool isLocked;

  /// Null when the viewer may not change this profile.
  final VoidCallback? onAdd;
  final ValueChanged<Allergy>? onEdit;

  @override
  Widget build(BuildContext context) {
    final edit = onEdit;
    return FamilySectionCard(
      icon: LucideIcons.shieldPlus,
      tint: NestTileTint.guava,
      title: FamilyCopy.sectionAllergies,
      actionIcon: isLocked ? LucideIcons.lock : LucideIcons.plus,
      actionLabel: isLocked
          ? FamilyCopy.lockedAction(FamilyCopy.addAllergy)
          : FamilyCopy.addAllergy,
      onAction: onAdd,
      child: isLocked
          ? const HealthLockedNote(message: FamilyCopy.allergiesLocked)
          : allergies.isEmpty
          ? const FamilySectionEmpty(message: FamilyCopy.noAllergies)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final allergy in allergies)
                  Padding(
                    key: ValueKey(allergy.key),
                    padding: const EdgeInsets.only(bottom: NestSpace.sm),
                    child: NestToneRow(
                      icon: allergy.severity.icon,
                      tone: allergy.severity.tone,
                      title: allergyName(allergy),
                      subtitle: allergy.note,
                      trailing: NestTag(
                        label: FamilyCopy.severityName(allergy.severity),
                        tone: allergy.severity.tone,
                      ),
                      onTap: edit == null ? null : () => edit(allergy),
                    ),
                  ),
              ],
            ),
    );
  }
}
