import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/school.dart';
import 'family_section_card.dart';
import 'family_section_empty.dart';

/// Where somebody goes to school and which grade — and, when the school is
/// nut-free, the rule that puts on them, said where the school is named.
class SchoolSection extends StatelessWidget {
  const SchoolSection({
    required this.school,
    required this.grade,
    required this.onEdit,
    super.key,
  });

  final School? school;
  final String? grade;

  /// Null when the viewer may not change this profile.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final attending = school;
    final isEmpty = attending == null && grade == null;
    return FamilySectionCard(
      icon: LucideIcons.graduationCap,
      tint: NestTileTint.lilac,
      title: FamilyCopy.sectionSchool,
      actionLabel: FamilyCopy.editSection(FamilyCopy.sectionSchool),
      onAction: onEdit,
      child: isEmpty
          ? const FamilySectionEmpty(message: FamilyCopy.noSchool)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FamilyCopy.schoolWithGrade(attending?.name, grade),
                  style: nest.text.bodyStrong,
                ),
                if (attending != null && attending.nutFree) ...[
                  const SizedBox(height: NestSpace.sm),
                  const NestTag(
                    label: FamilyCopy.schoolNutFree,
                    tone: NestTagTone.warning,
                    icon: LucideIcons.utensilsCrossed,
                  ),
                ],
              ],
            ),
    );
  }
}
