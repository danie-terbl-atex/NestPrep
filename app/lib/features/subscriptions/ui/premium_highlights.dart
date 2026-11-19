import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/premium_feature.dart';
import '../model/premium_highlight.dart';
import 'highlights_offered.dart';
import 'premium_highlight_look.dart';

/// Everything in Premium as cards, two to a row, the area [feature] belongs
/// to first, full width and marked. One to a row once the text is large.
class PremiumHighlights extends StatelessWidget {
  const PremiumHighlights({required this.feature, super.key});

  final PremiumFeature feature;

  static const _wideTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final offered = highlightsOffered(context);
    final area = PremiumHighlight.of(feature);
    final reached = offered.contains(area) ? area : null;
    final rest = [
      for (final highlight in offered)
        if (highlight != reached) highlight,
    ];
    final perRow = MediaQuery.textScalerOf(context).scale(1) > _wideTextScale
        ? 1
        : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reached != null) ...[
          _HighlightCard(highlight: reached, isReached: true),
          const SizedBox(height: NestSpace.md),
        ],
        for (var at = 0; at < rest.length; at += perRow) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var column = 0; column < perRow; column++) ...[
                  if (column > 0) const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: at + column < rest.length
                        ? _HighlightCard(highlight: rest[at + column])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: NestSpace.md),
        ],
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight, this.isReached = false});

  final PremiumHighlight highlight;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ink = nest.colors.ink;
    return Semantics(
      container: true,
      child: NestCard(
        variant: NestCardVariant.flat,
        tint: highlight.tint,
        padding: const EdgeInsets.all(NestSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: NestSpace.md,
              runSpacing: NestSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(highlight.icon, size: NestSize.iconLarge, color: ink),
                if (isReached)
                  const NestTag(
                    label: SubscriptionCopy.reachedFor,
                    icon: LucideIcons.sparkles,
                  ),
              ],
            ),
            const SizedBox(height: NestSpace.md),
            Text(
              SubscriptionCopy.highlightTitle(highlight),
              style: nest.text.bodyStrong.copyWith(color: ink),
            ),
            const SizedBox(height: NestSpace.xxs),
            Text(
              SubscriptionCopy.highlightBody(highlight),
              style: nest.text.label.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
