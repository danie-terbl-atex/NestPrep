import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/referral_copy.dart';

/// The top of *give a month, get a month*: two homes and a gift between
/// them, and the promise in one warm sentence (subscriptions ADR-0002). The
/// picture is decoration; the words carry it for a screen reader (`FE-13`).
class ReferralHero extends StatelessWidget {
  const ReferralHero({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      children: [
        const ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NestIconTile(icon: LucideIcons.house, tint: NestTileTint.basil),
              SizedBox(width: NestSpace.md),
              NestIconTile(
                icon: LucideIcons.gift,
                tint: NestTileTint.butter,
                size: NestSize.mark,
                iconSize: NestSize.iconMark,
              ),
              SizedBox(width: NestSpace.md),
              NestIconTile(icon: LucideIcons.house, tint: NestTileTint.lilac),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        Text(
          ReferralCopy.heroTitle,
          style: nest.text.headline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          ReferralCopy.heroBody,
          style: nest.text.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
