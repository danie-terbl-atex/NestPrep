import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/school.dart';
import 'family_section_card.dart';
import 'family_section_empty.dart';

/// The household's schools, each with its nut-free rule — the one place a
/// school is set nut-free for every child at it at once.
class SchoolsCard extends StatelessWidget {
  const SchoolsCard({
    required this.schools,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final List<School> schools;

  /// Both null for anybody but an admin.
  final VoidCallback? onAdd;
  final ValueChanged<School>? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final edit = onEdit;
    return FamilySectionCard(
      icon: LucideIcons.graduationCap,
      tint: NestTileTint.lilac,
      title: FamilyCopy.schoolsTitle,
      actionIcon: LucideIcons.plus,
      actionLabel: FamilyCopy.addSchool,
      onAction: onAdd,
      child: schools.isEmpty
          ? const FamilySectionEmpty(message: FamilyCopy.schoolsEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final school in schools)
                  NestListRow(
                    key: ValueKey(school.id),
                    title: school.name,
                    trailing: school.nutFree
                        ? const NestTag(
                            label: FamilyCopy.nutFree,
                            tone: NestTagTone.warning,
                            icon: LucideIcons.utensilsCrossed,
                          )
                        : edit == null
                        ? null
                        : Icon(
                            LucideIcons.chevronRight,
                            size: NestSize.iconMedium,
                            color: nest.colors.inkTertiary,
                          ),
                    onTap: edit == null ? null : () => edit(school),
                  ),
              ],
            ),
    );
  }
}
