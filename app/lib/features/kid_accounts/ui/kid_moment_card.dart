import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A moment on a kid's home that is worth a big picture: every job done, or no
/// jobs at all today (accounts ADR-0003). It rises in once and rests — a
/// celebration that arrives, never one that loops (design-system ADR-0002).
class KidMomentCard extends StatelessWidget {
  const KidMomentCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final NestTileTint tint;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestRiseIn(
      child: NestCard(
        variant: NestCardVariant.tinted,
        child: Semantics(
          container: true,
          child: Column(
            children: [
              NestIconTile(
                icon: icon,
                tint: tint,
                size: NestSize.mark,
                iconSize: NestSize.iconMark,
              ),
              const SizedBox(height: NestSpace.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: nest.text.headline,
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: nest.text.bodySecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
