import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import 'family_section_card.dart';
import 'family_section_empty.dart';

/// Clothes and shoe sizes, side by side, the way somebody standing in a shop
/// wants to read them.
class SizesSection extends StatelessWidget {
  const SizesSection({
    required this.clothingSize,
    required this.shoeSize,
    required this.onEdit,
    super.key,
  });

  final String? clothingSize;
  final String? shoeSize;

  /// Null when the viewer may not change this profile.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isEmpty = clothingSize == null && shoeSize == null;
    return FamilySectionCard(
      icon: LucideIcons.shirt,
      tint: NestTileTint.accent,
      title: FamilyCopy.sectionSizes,
      actionLabel: FamilyCopy.editSection(FamilyCopy.sectionSizes),
      onAction: onEdit,
      child: isEmpty
          ? const FamilySectionEmpty(message: FamilyCopy.noSizes)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Size(
                    label: FamilyCopy.clothingSize,
                    value: clothingSize,
                  ),
                ),
                const SizedBox(width: NestSpace.sm),
                Expanded(
                  child: _Size(label: FamilyCopy.shoeSize, value: shoeSize),
                ),
              ],
            ),
    );
  }
}

class _Size extends StatelessWidget {
  const _Size({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: nest.text.caption),
          const SizedBox(height: NestSpace.xxs),
          Text(value ?? FamilyCopy.sizeNotSet, style: nest.text.title),
        ],
      ),
    );
  }
}
