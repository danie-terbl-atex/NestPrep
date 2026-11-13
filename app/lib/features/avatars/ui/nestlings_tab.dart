import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../model/avatar_stage.dart';
import '../model/avatar_studio.dart';
import 'nestling_picture.dart';
import 'stage_progress_card.dart';

class NestlingsTab extends StatelessWidget {
  const NestlingsTab({
    required this.studio,
    required this.isSelf,
    required this.onPick,
    required this.onStage,
    super.key,
  });

  final AvatarStudio studio;
  final bool isSelf;
  final ValueChanged<String> onPick;
  final ValueChanged<int> onStage;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final chosen = studio.nestlingName();
    final isKid = studio.isKid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isKid)
          StageProgressCard(studio: studio, isSelf: isSelf)
        else ...[
          Text(AvatarCopy.pickNestlingBody, style: nest.text.bodySecondary),
          if (chosen != null) ...[
            const SizedBox(height: NestSpace.lg),
            Text(
              AvatarCopy.howGrownUp,
              style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
            ),
            const SizedBox(height: NestSpace.sm),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final stage in AvatarStage.all)
                  NestChip(
                    label: AvatarCopy.stageName(stage),
                    isSelected: stage == studio.stage,
                    onTap: () => onStage(stage),
                  ),
              ],
            ),
          ],
        ],
        const SizedBox(height: NestSpace.xl),
        NestSectionHeader(
          title: isKid && isSelf
              ? AvatarCopy.kidPickTitle
              : AvatarCopy.pickNestling,
        ),
        const SizedBox(height: NestSpace.sm),
        NestPickGrid(
          children: [
            for (final nestling in studio.library.nestlings)
              NestPickTile(
                key: ValueKey('nestling-${nestling.name}'),
                label: nestling.label,
                semanticLabel: AvatarCopy.nestlingAt(
                  nestling.label,
                  studio.stage,
                ),
                isSelected: nestling.name == chosen,
                onTap: () => onPick(nestling.name),
                picture: NestlingPicture(
                  name: nestling.name,
                  label: nestling.label,
                  stage: studio.stage,
                  color: studio.member.color,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
