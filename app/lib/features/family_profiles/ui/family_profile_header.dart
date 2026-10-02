import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/family_entry.dart';

/// The top of a profile: who this is, how old, and whether they are a child —
/// a chip a parent can flip, or a plain tag for anybody who cannot.
class FamilyProfileHeader extends StatelessWidget {
  const FamilyProfileHeader({
    required this.entry,
    required this.age,
    required this.onToggleChild,
    super.key,
  });

  final FamilyEntry entry;

  /// Null when the household does not know the birth year.
  final int? age;

  /// Null when the viewer may not change this profile.
  final VoidCallback? onToggleChild;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final member = entry.member;
    final years = age;
    final toggle = onToggleChild;
    final subtitle = [
      AppCopy.roleName(member.roleName),
      if (years != null) FamilyCopy.age(years),
    ].join(' · ');
    return Row(
      children: [
        NestAvatar(
          name: member.displayName,
          color: member.color,
          size: NestSize.mark,
        ),
        const SizedBox(width: NestSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.displayName, style: nest.text.headline),
              Text(subtitle, style: nest.text.bodySecondary),
              const SizedBox(height: NestSpace.sm),
              if (toggle != null) ...[
                NestChip(
                  label: FamilyCopy.isChild,
                  icon: entry.isChild ? LucideIcons.check : LucideIcons.baby,
                  isSelected: entry.isChild,
                  semanticLabel: FamilyCopy.markAsChild,
                  onTap: toggle,
                ),
                if (!entry.isChild) ...[
                  const SizedBox(height: NestSpace.xs),
                  Text(FamilyCopy.isChildHint, style: nest.text.caption),
                ],
              ] else if (entry.isChild)
                const NestTag(
                  label: FamilyCopy.isChild,
                  tone: NestTagTone.accent,
                  icon: LucideIcons.baby,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
