import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// Premium's mark: the crest in the app's accent tile, with two small
/// sparkles beside it. Decoration only — the headline under it says what it
/// is, so a screen reader skips it (`FE-13`).
class PremiumMark extends StatelessWidget {
  const PremiumMark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: NestSize.mark + NestSpace.xxxl,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const NestIconTile(
              icon: LucideIcons.award,
              size: NestSize.mark,
              iconSize: NestSize.iconMark,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                LucideIcons.sparkles,
                size: NestSize.iconMedium,
                color: colors.accent,
              ),
            ),
            Positioned(
              bottom: NestSpace.sm,
              left: 0,
              child: Icon(
                LucideIcons.sparkles,
                size: NestSize.iconSmall,
                color: colors.accentInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
