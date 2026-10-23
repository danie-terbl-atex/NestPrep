import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// How a recipe can be made ahead — the Sunday-prep note — set apart in a
/// tinted card after the method, where a cook planning the week looks.
class RecipeMakeAhead extends StatelessWidget {
  const RecipeMakeAhead({required this.note, super.key});

  final String note;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NestIconTile(
            icon: LucideIcons.calendarClock,
            tint: NestTileTint.lilac,
            size: NestSize.avatarMedium,
            iconSize: NestSize.iconSmall,
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(RecipeCopy.aheadHeader, style: nest.text.bodyStrong),
                const SizedBox(height: NestSpace.xxs),
                Text(note, style: nest.text.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
