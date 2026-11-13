import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../../household/model/member.dart';
import '../model/avatar_library.dart';
import '../model/avatar_stage.dart';
import 'nestling_picture.dart';

abstract final class HatchCelebration {
  static const length = Duration(milliseconds: 4200);

  static void show(
    BuildContext context, {
    required Member kid,
    required String nestling,
    required int from,
    required int to,
  }) {
    final label =
        AvatarLibrary.bundled.nestling(nestling)?.label ?? kid.displayName;
    final (title, message) = from == AvatarStage.egg
        ? (AvatarCopy.hatchedTitle, AvatarCopy.hatchedBody(label))
        : to == AvatarStage.flyer
        ? (AvatarCopy.flewTitle, AvatarCopy.flewBody)
        : (AvatarCopy.grewTitle, AvatarCopy.grewBody);
    NestCelebration.show(
      context,
      title: title,
      message: message,
      length: length,
      picture: NestHatchReveal(
        duration: length,
        before: NestlingPicture(
          name: nestling,
          label: label,
          stage: from,
          color: kid.color,
        ),
        after: NestlingPicture(
          name: nestling,
          label: label,
          stage: to,
          color: kid.color,
        ),
      ),
    );
  }
}
