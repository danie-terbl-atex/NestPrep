import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/home_care_board.dart';

/// The three piles, each with how many jobs are in it. They stay on screen
/// whatever is in the pile, so an empty pile never hides the way to the
/// others (`FE-08`).
class JobPileChips extends StatelessWidget {
  const JobPileChips({
    required this.selected,
    required this.counts,
    required this.onSelect,
    super.key,
  });

  final JobPile selected;
  final Map<JobPile, int> counts;
  final ValueChanged<JobPile> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        for (final pile in JobPile.values)
          NestChip(
            label: HomeCareCopy.pileWithCount(pile, counts[pile] ?? 0),
            icon: switch (pile) {
              JobPile.toDo => Icons.cleaning_services_outlined,
              JobPile.toReview => Icons.rate_review_outlined,
              JobPile.done => Icons.verified_outlined,
            },
            isSelected: pile == selected,
            onTap: () => onSelect(pile),
          ),
      ],
    );
  }
}
