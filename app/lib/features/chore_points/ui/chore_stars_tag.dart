import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../../todos/model/task.dart';

/// What a chore is worth, on the to-do row (todos ADR-0003): its stars, and
/// that a parent checks it first when one does. In words beside the star
/// (`FE-13`).
class ChoreStarsTag extends StatelessWidget {
  const ChoreStarsTag({required this.task, super.key});

  final Task task;

  @override
  Widget build(BuildContext context) => NestTag(
    label: task.needsApproval
        ? PointsCopy.starsChecked(task.points)
        : PointsCopy.starsCount(task.points),
    tone: NestTagTone.warning,
    icon: Icons.star_rounded,
  );
}
