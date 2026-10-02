import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/ui/family_section_card.dart';
import '../../family_profiles/ui/family_section_empty.dart';

/// The things that comfort the child — the blue bunny, the yellow blanket.
class ComfortSection extends StatelessWidget {
  const ComfortSection({required this.items, required this.onEdit, super.key});

  final List<String> items;

  /// Null when the viewer may not change the card.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return FamilySectionCard(
      icon: LucideIcons.toyBrick,
      tint: NestTileTint.butter,
      title: NannyCopy.comfort,
      actionLabel: NannyCopy.editComfort,
      onAction: onEdit,
      child: items.isEmpty
          ? const FamilySectionEmpty(message: NannyCopy.noComfort)
          : Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final item in items)
                  NestTag(
                    label: item,
                    tone: NestTagTone.accent,
                    icon: LucideIcons.heart,
                  ),
              ],
            ),
    );
  }
}
