import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// Premium's seal: the crest and its name on Butter, the same in both themes
/// (subscriptions ADR-0007). It sits beside the wordmark, so it grows only a
/// little with the text setting rather than pushing the brand off its line.
class NestPremiumSeal extends StatelessWidget {
  const NestPremiumSeal({required this.label, super.key});

  final String label;

  static const _maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: NestColors.butter,
          shape: StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NestSpace.md,
            vertical: NestSpace.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.award,
                size: NestSize.iconBadge,
                color: NestColors.inkBrand,
              ),
              const SizedBox(width: NestSpace.xs),
              Text(
                label,
                maxLines: 1,
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: _maxTextScale),
                style: nest.text.label.copyWith(color: NestColors.inkBrand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
