import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/kid_chore_note.dart';

/// What a child's job is worth, and where its stars are, as one tag on the
/// job's tile (todos ADR-0003). Nothing at all for a job with no stars.
///
/// The words are `PointsCopy.kidNote`, which the tile also reads aloud, so
/// what is seen and what is heard are the same sentence (`FE-13`).
class KidChoreStars extends StatelessWidget {
  const KidChoreStars({required this.note, super.key});

  final KidChoreNote note;

  @override
  Widget build(BuildContext context) {
    final label = PointsCopy.kidNote(note);
    if (label == null) return const SizedBox.shrink();
    final (tone, icon) = switch (note) {
      // Gold wherever there are stars, earned or not — and it stands out on
      // a done job's green, where a green tag would disappear into it.
      NoStars() ||
      Earns() ||
      Earned() => (NestTagTone.warning, LucideIcons.star),
      TryAgain() => (NestTagTone.warning, LucideIcons.refreshCw),
      Counting() => (NestTagTone.neutral, LucideIcons.ellipsis),
      WaitingForGrownUp() => (NestTagTone.accent, LucideIcons.hourglass),
    };
    return NestTag(label: label, tone: tone, icon: icon);
  }
}
