import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/allergy.dart';
import 'allergy_names.dart';
import 'family_section_card.dart';
import 'family_section_empty.dart';
import 'severity_look.dart';

/// A person's allergies, most dangerous first, each in its severity's tone
/// with the severity named beside it. Tapping one edits it; the corner adds
/// one. Both are absent for somebody who may not change this profile.
class AllergySection extends StatelessWidget {
  const AllergySection({
    required this.allergies,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final List<Allergy> allergies;

  /// Null when the viewer may not change this profile.
  final VoidCallback? onAdd;
  final ValueChanged<Allergy>? onEdit;

  @override
  Widget build(BuildContext context) {
    final edit = onEdit;
    return FamilySectionCard(
      icon: Icons.health_and_safety_outlined,
      tint: NestTileTint.guava,
      title: FamilyCopy.sectionAllergies,
      actionIcon: Icons.add,
      actionLabel: FamilyCopy.addAllergy,
      onAction: onAdd,
      child: allergies.isEmpty
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
