import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/task_occurrence.dart';
import 'chore_picture_view.dart';

void celebrateChore(
  BuildContext context, {
  required String kidName,
  required TaskOccurrence chore,
  required bool finishesTheDay,
}) {
  final name = kidName.trim().split(' ').first;
  final task = chore.task;
  NestCelebration.show(
    context,
    title: finishesTheDay ? KidCopy.allDone(name) : KidCopy.wellDone(name),
    message: finishesTheDay ? KidCopy.everyChoreDone : task.title,
    note: task.needsApproval
        ? KidCopy.grownUpWillCheck
        : task.carriesStars
        ? PointsCopy.plusStars(task.points)
        : null,
    picture: !finishesTheDay && task.chorePicture != null
        ? ChorePictureView(id: task.picture, size: NestSize.stickerHero)
        : null,
  );
}
