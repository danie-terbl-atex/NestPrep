import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';

/// What a chore is worth, in the task sheet (todos ADR-0003): none, or a few
/// sizes of stars, and whether a parent checks it first. Offered to family
/// only — the rules refuse stars from anybody else.
///
/// A starred chore must name who earns it; the sheet says so here, beside the
/// choice, when nobody is picked yet.
class ChoreStarsField extends StatelessWidget {
  const ChoreStarsField({
    required this.points,
    required this.needsApproval,
    required this.namesSomebody,
    required this.onPoints,
    required this.onNeedsApproval,
    super.key,
  });

  /// The sizes a parent picks from — a chore is a few stars, a big job more.
  static const choices = [0, 1, 2, 3, 5, 10, 20];

  final int points;
  final bool needsApproval;

  /// Whether the chore has at least one assignee.
  final bool namesSomebody;
  final ValueChanged<int> onPoints;
  final ValueChanged<bool> onNeedsApproval;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    // A chore written with a size not offered here keeps it, and shows it.
    final sizes = choices.contains(points) ? choices : [...choices, points];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PointsCopy.choreStarsLabel,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final size in sizes)
              NestChip(
                label: size == 0
                    ? PointsCopy.choreNoStars
                    : PointsCopy.starsCount(size),
                icon: size == 0 ? null : LucideIcons.star,
                isSelected: points == size,
                onTap: () => onPoints(size),
              ),
          ],
        ),
        if (points > 0) ...[
          const SizedBox(height: NestSpace.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NestChip(
              label: PointsCopy.choreNeedsApproval,
              icon: needsApproval
                  ? LucideIcons.squareCheck
                  : LucideIcons.square,
              isSelected: needsApproval,
              onTap: () => onNeedsApproval(!needsApproval),
            ),
          ),
          if (!namesSomebody) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              PointsCopy.choreNeedsSomebody,
              style: nest.text.caption.copyWith(color: nest.colors.warning),
            ),
          ],
        ],
      ],
    );
  }
}
