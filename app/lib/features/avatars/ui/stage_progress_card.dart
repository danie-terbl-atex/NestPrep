import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../model/avatar_stage.dart';
import '../model/avatar_studio.dart';
import 'nestling_picture.dart';

class StageProgressCard extends StatelessWidget {
  const StageProgressCard({
    required this.studio,
    required this.isSelf,
    super.key,
  });

  final AvatarStudio studio;
  final bool isSelf;

  static const fallbackNestling = 'pip';

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final progress = studio.progress;
    final name = studio.nestlingName() ?? fallbackNestling;
    final label = studio.library.nestling(name)?.label ?? name;
    final color = studio.member.color;
    final (title, body) = !isSelf
        ? (
            AvatarCopy.nestlingAt(label, studio.stage),
            AvatarCopy.parentStageBody(studio.member.displayName),
          )
        : switch (progress.stage) {
            AvatarStage.egg => (AvatarCopy.kidEggTitle, AvatarCopy.kidEggBody),
            AvatarStage.hatchling => (
              AvatarCopy.kidHatchlingTitle,
              AvatarCopy.kidHatchlingBody(progress.toGo),
            ),
            AvatarStage.fledgling => (
              AvatarCopy.kidFledglingTitle,
              AvatarCopy.kidFledglingBody(progress.toGo),
            ),
            _ => (AvatarCopy.kidFlyerTitle, AvatarCopy.kidFlyerBody),
          };
    final next = progress.next;
    return NestCard(
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: nest.text.title),
            const SizedBox(height: NestSpace.xs),
            Text(body, style: nest.text.bodySecondary),
            const SizedBox(height: NestSpace.lg),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NestlingPicture(
                    name: name,
                    label: label,
                    stage: progress.stage,
                    color: color,
                    size: NestSize.avatarLarge,
                  ),
                  if (next != null) ...[
                    const SizedBox(width: NestSpace.md),
                    Icon(
                      LucideIcons.arrowRight,
                      size: NestSize.iconMedium,
                      color: nest.colors.inkSecondary,
                    ),
                    const SizedBox(width: NestSpace.md),
                    NestlingPicture(
                      name: name,
                      label: label,
                      stage: next,
                      color: color,
                      size: NestSize.avatarLarge,
                    ),
                  ],
                ],
              ),
            ),
            if (next != null && progress.stage != AvatarStage.egg) ...[
              const SizedBox(height: NestSpace.lg),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NestRadius.pill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress.fraction),
                    duration: NestMotion.of(context).slow,
                    curve: NestMotion.enter,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: NestSpace.sm,
                      backgroundColor: nest.colors.surfaceTint,
                      color: nest.colors.success,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                AvatarCopy.daysInARow(progress.done, progress.needed),
                style: nest.text.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
