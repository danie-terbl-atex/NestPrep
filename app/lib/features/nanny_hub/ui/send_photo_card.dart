import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/photo_picker.dart';

/// Shift mode's way of sending the parents a picture: two big buttons, camera
/// first, and how many have gone so far. It only reports the tap; picking,
/// captioning and sending belong to the screen and its controller (`FE-05`).
/// While one photo is on its way the buttons wait, so a second tap is not a
/// second photo (`FE-10`).
class SendPhotoCard extends StatelessWidget {
  const SendPhotoCard({
    required this.sentCount,
    required this.isSending,
    required this.onPick,
    required this.onOpenFeed,
    super.key,
  });

  final int sentCount;
  final bool isSending;
  final ValueChanged<PhotoSource> onPick;
  final VoidCallback onOpenFeed;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NestIconTile(
                icon: LucideIcons.camera,
                tint: NestTileTint.lilac,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(NannyPhotoCopy.sendTitle, style: nest.text.title),
                    const SizedBox(height: NestSpace.xxs),
                    Text(
                      NannyPhotoCopy.sendBody,
                      style: nest.text.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: isSending ? NannyPhotoCopy.sending : NannyPhotoCopy.takeOne,
            icon: LucideIcons.camera,
            isLoading: isSending,
            onPressed: isSending ? null : () => onPick(PhotoSource.camera),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: NannyPhotoCopy.chooseOne,
            icon: LucideIcons.images,
            variant: NestButtonVariant.tonal,
            onPressed: isSending ? null : () => onPick(PhotoSource.library),
          ),
          if (sentCount > 0) ...[
            const SizedBox(height: NestSpace.md),
            NestListRow(
              leading: const Icon(LucideIcons.circleCheck),
              title: NannyPhotoCopy.sentSoFar(sentCount),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: onOpenFeed,
            ),
          ],
        ],
      ),
    );
  }
}
