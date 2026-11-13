import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_creation.dart';
import '../model/avatar_studio.dart';
import '../state/creation_step.dart';
import 'buddy_sentence_card.dart';
import 'creation_egg.dart';
import 'hatch_celebration.dart';
import 'stored_avatar_picture.dart';

class CreationReadyView extends StatelessWidget {
  const CreationReadyView({
    required this.studio,
    required this.householdId,
    required this.ready,
    required this.onUse,
    required this.onKeep,
    super.key,
  });

  static const portraitShape = 16 / 9;

  final AvatarStudio studio;
  final String householdId;
  final CreationReady ready;
  final VoidCallback onUse;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final recipe = ready.creation.recipe;
    final isPortrait = recipe == CreationRecipe.portrait;
    final picture = StoredAvatarPicture.made(
      householdId: householdId,
      memberId: ready.creation.memberId,
      hash: ready.imageHash,
      label: isPortrait
          ? AvatarCreationCopy.portraitLabel
          : AvatarCreationCopy.madeLabel,
      aspectRatio: isPortrait ? portraitShape : 1,
    );
    final buddy = ready.buddy;
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPortrait)
            picture
          else
            Center(
              child: NestHatchReveal(
                duration: HatchCelebration.length,
                size: NestSize.creationReveal,
                before: CreationEgg(studio: studio),
                after: picture,
              ),
            ),
          const SizedBox(height: NestSpace.xl),
          Row(
            children: [
              const NestTwig(pose: NestTwigPose.celebrate),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    AvatarCreationCopy.readyTitle(recipe),
                    style: nest.text.title,
                  ),
                ),
              ),
            ],
          ),
          if (buddy != null && !buddy.isEmpty) ...[
            const SizedBox(height: NestSpace.md),
            BuddySentenceCard(buddy: buddy, isCompact: true),
          ],
          const SizedBox(height: NestSpace.xl),
          if (isPortrait) ...[
            Text(
              AvatarCreationCopy.portraitOnFrame,
              style: nest.text.bodySecondary,
            ),
            const SizedBox(height: NestSpace.lg),
            NestButton(
              label: AvatarCreationCopy.done,
              icon: LucideIcons.check,
              onPressed: onKeep,
            ),
          ] else ...[
            NestButton(
              label: AvatarCreationCopy.useIt,
              icon: LucideIcons.check,
              onPressed: onUse,
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AvatarCreationCopy.keepOnShelf,
              variant: NestButtonVariant.outline,
              onPressed: onKeep,
            ),
          ],
        ],
      ),
    );
  }
}
