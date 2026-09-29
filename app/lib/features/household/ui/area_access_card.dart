import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/access_level.dart';
import '../model/household_area.dart';
import 'area_tile.dart';

/// One area in the access editor: what it is, the levels it accepts as chips,
/// and a sentence saying what the chosen one means for this person — the
/// choice is spelled out, never left to the chip's one word (household
/// ADR-0003).
class AreaAccessCard extends StatelessWidget {
  const AreaAccessCard({
    required this.area,
    required this.level,
    required this.personName,
    required this.onChanged,
    super.key,
  });

  final HouseholdArea area;
  final AccessLevel level;
  final String personName;
  final ValueChanged<AccessLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final isOpen = level.isAnything;
    return NestCard(
      variant: isOpen ? NestCardVariant.raised : NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AreaTile(area: area),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AccessCopy.areaName(area),
                      style: nest.text.bodyStrong,
                    ),
                    Text(
                      AccessCopy.areaBlurb(area),
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final choice in area.levels)
                NestChip(
                  label: AccessCopy.levelName(choice),
                  isSelected: choice == level,
                  onTap: () => onChanged(choice),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            AccessCopy.levelMeaning(level, personName),
            style: nest.text.caption.copyWith(
              color: isOpen ? nest.colors.accentInk : nest.colors.inkTertiary,
            ),
          ),
          if (area == HouseholdArea.medical && isOpen) ...[
            const SizedBox(height: NestSpace.sm),
            const NestBanner(
              message: AccessCopy.accessMedicalCaution,
              tone: NestBannerTone.warning,
            ),
          ],
        ],
      ),
    );
  }
}
