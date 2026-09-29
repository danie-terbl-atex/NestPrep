import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/kid_points.dart';
import 'kid_stars_card.dart';

/// The stars card in all four of its states (`FE-08`), for the kid home: a
/// placeholder the card's size while the stars load, a small retry if they
/// cannot, and the card. It never replaces the rest of the day — jobs and
/// food are still worth seeing while the stars are away.
class KidStarsSection extends StatelessWidget {
  const KidStarsSection({
    required this.points,
    required this.onRetry,
    super.key,
  });

  final AsyncState<KidPoints> points;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (points) {
    // A still shape rather than the kit's pulsing skeleton: the rest of the
    // day is already on screen and settled, and a pulse here would be the
    // one thing on a child's home that never comes to rest while a slow
    // network holds the stars back (design-system ADR-0002).
    AsyncLoading() => DecoratedBox(
      key: const ValueKey('stars-loading'),
      decoration: BoxDecoration(
        color: NestTheme.of(context).colors.skeleton,
        borderRadius: BorderRadius.circular(NestRadius.xl),
      ),
      child: const SizedBox(height: NestSize.mark + NestSpace.xxxl),
    ),
    AsyncFailure(:final failure) => NestCard(
      variant: NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppCopy.failure(failure),
            style: NestTheme.of(context).text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: AppCopy.retry,
            variant: NestButtonVariant.tonal,
            size: NestButtonSize.medium,
            onPressed: onRetry,
          ),
        ],
      ),
    ),
    AsyncData(:final value) => KidStarsCard(points: value),
  };
}
