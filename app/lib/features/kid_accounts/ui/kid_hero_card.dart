import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/kid_day.dart';

/// The top of a kid's home: their own colour, their initial, their name, and
/// how far through today's jobs they are (accounts ADR-0003).
///
/// The fill is the kid's member colour and the ink is that colour's own
/// on-fill, which the member palette proves legible in both themes — so the
/// card is theirs without being anybody's guess at contrast (`FE-13`). The
/// progress is said in words as well as drawn; the bar is never the only
/// signal.
class KidHeroCard extends StatelessWidget {
  const KidHeroCard({required this.day, super.key});

  final KidDay day;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final swatch = nest.members.of(day.me.color);
    final total = day.chores.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: swatch.fill,
        borderRadius: BorderRadius.circular(NestRadius.xxl),
        boxShadow: nest.shadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(NestSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NestAvatar(
                  name: day.me.displayName,
                  color: day.me.color,
                  size: NestSize.mark,
                  isHighlighted: true,
                ),
                const SizedBox(width: NestSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        KidCopy.greeting(_firstName(day.me.displayName)),
                        style: nest.text.headline.copyWith(
                          color: swatch.onFill,
                        ),
                      ),
                      Text(
                        NestDates.full(day.today, day.today),
                        style: nest.text.label.copyWith(color: swatch.onFill),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: NestSpace.lg),
              Text(
                KidCopy.choresProgress(day.doneCount, total),
                style: nest.text.bodyStrong.copyWith(color: swatch.onFill),
              ),
              const SizedBox(height: NestSpace.sm),
              _ProgressBar(fraction: day.doneCount / total),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Hi, Mia!" rather than "Hi, Mia Parker!" — a child is greeted the way the
/// family says their name.
String _firstName(String displayName) {
  final words = displayName.trim().split(RegExp(r'\s+'));
  return words.first.isEmpty ? displayName : words.first;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NestRadius.pill),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: NestMotion.of(context).slow,
          curve: NestMotion.enter,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: NestSpace.md,
            backgroundColor: nest.colors.surface,
            color: nest.colors.success,
          ),
        ),
      ),
    );
  }
}
