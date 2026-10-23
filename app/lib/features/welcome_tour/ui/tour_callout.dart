import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/copy/tour_copy.dart';
import '../model/tour_premium.dart';
import '../model/tour_stop.dart';
import '../model/tour_target.dart';

/// What a callout's buttons do; the layer decides what that means.
@immutable
class TourCalloutActions {
  const TourCalloutActions({
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
}

/// The words beside a spotlighted component (welcome-tour ADR-0002): the
/// chapter, where in the tour, a title, a line or two, the premium tag
/// where it applies, and the way on, back and out. It scrolls inside itself
/// when the text setting makes it taller than the room it was given.
class TourCallout extends StatelessWidget {
  const TourCallout({
    required this.stop,
    required this.shown,
    required this.number,
    required this.count,
    required this.nextLabel,
    required this.actions,
    super.key,
  });

  final TourStop stop;

  /// What is actually spotlighted — the stop's own target or a fallback.
  final TourTarget shown;
  final int number;
  final int count;
  final String nextLabel;
  final TourCalloutActions actions;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final onBack = actions.onBack;
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The words scroll when the text setting makes them taller than
          // the room; the way on, back and out never do.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: NestSpace.sm,
                    children: [
                      NestEyebrow(TourCopy.chapter(stop.place)),
                      Text(
                        TourCopy.stepOf(number, count),
                        style: nest.text.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: NestSpace.sm),
                  Semantics(
                    header: true,
                    child: Text(
                      TourCopy.title(shown, isLookOnly: stop.isLookOnly),
                      style: nest.text.title,
                    ),
                  ),
                  const SizedBox(height: NestSpace.xs),
                  Text(
                    TourCopy.body(
                      shown,
                      isLookOnly: stop.isLookOnly,
                      premium: stop.premium,
                    ),
                    style: nest.text.bodySecondary,
                  ),
                  if (stop.premium != TourPremium.none) ...[
                    const SizedBox(height: NestSpace.sm),
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: NestTag(
                        label: SubscriptionCopy.premium,
                        tone: NestTagTone.accent,
                        icon: LucideIcons.award,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: NestSpace.md),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: NestSpace.xs,
            runSpacing: NestSpace.xs,
            children: [
              NestButton(
                key: const ValueKey('tour-skip'),
                label: TourCopy.skip,
                variant: NestButtonVariant.ghost,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: actions.onSkip,
              ),
              if (onBack != null)
                NestButton(
                  key: const ValueKey('tour-back'),
                  label: TourCopy.back,
                  variant: NestButtonVariant.outline,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: onBack,
                ),
              NestButton(
                key: const ValueKey('tour-next'),
                label: nextLabel,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: actions.onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
