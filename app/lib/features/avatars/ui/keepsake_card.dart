import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_creation.dart';
import '../model/avatar_keepsake.dart';
import 'buddy_sentence_card.dart';
import 'creation_ready_view.dart';
import 'stored_avatar_picture.dart';

class KeepsakeCard extends StatelessWidget {
  const KeepsakeCard({
    required this.keepsake,
    required this.householdId,
    required this.isWorn,
    required this.isDeleting,
    required this.onUse,
    required this.onDelete,
    super.key,
  });

  final AvatarKeepsake keepsake;
  final String householdId;
  final bool isWorn;
  final bool isDeleting;
  final VoidCallback? onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final made = StoredAvatarPicture.made(
      householdId: householdId,
      memberId: keepsake.memberId,
      hash: keepsake.imageHash,
      label: keepsake.isPortrait
          ? AvatarCreationCopy.portraitLabel
          : AvatarCreationCopy.madeLabel,
      aspectRatio: keepsake.isPortrait ? CreationReadyView.portraitShape : 1,
    );
    final original = keepsake.originalPath;
    final buddy = keepsake.buddy;
    final style = keepsake.style;
    final onUse = this.onUse;
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (keepsake.isPortrait)
            made
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Side(
                    caption: AvatarCreationCopy.then,
                    child: original != null
                        ? StoredAvatarPicture.original(
                            path: original,
                            label: AvatarCreationCopy.originalLabel(
                              keepsake.recipe,
                            ),
                          )
                        : AspectRatio(
                            aspectRatio: 1,
                            child: Center(
                              child: LayoutBuilder(
                                builder: (context, constraints) => NestIconTile(
                                  icon: keepsake.recipe == CreationRecipe.buddy
                                      ? LucideIcons.wandSparkles
                                      : LucideIcons.image,
                                  tint: NestTileTint.lilac,
                                  size: constraints.maxWidth,
                                  iconSize: constraints.maxWidth / 3,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: _Side(caption: AvatarCreationCopy.now, child: made),
                ),
              ],
            ),
          if (buddy != null && !buddy.isEmpty) ...[
            const SizedBox(height: NestSpace.md),
            BuddySentenceCard(buddy: buddy, isCompact: true),
          ],
          if (style != null) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              AvatarCreationCopy.styleTitle(style),
              style: nest.text.caption,
            ),
          ],
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isWorn)
                const NestTag(
                  label: AvatarCreationCopy.wearing,
                  tone: NestTagTone.success,
                  icon: LucideIcons.check,
                )
              else if (onUse != null)
                NestButton(
                  label: AvatarCreationCopy.useAgain,
                  icon: LucideIcons.check,
                  variant: NestButtonVariant.tonal,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: isDeleting ? null : onUse,
                ),
              NestButton(
                label: isDeleting
                    ? AvatarCreationCopy.deleting
                    : AvatarCreationCopy.delete,
                icon: LucideIcons.trash2,
                variant: NestButtonVariant.ghost,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: isDeleting ? null : onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(caption, style: nest.text.eyebrow),
        const SizedBox(height: NestSpace.xs),
        child,
      ],
    );
  }
}
