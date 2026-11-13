import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/avatar_studio.dart';
import 'creation_egg.dart';

class CreationTooSlowView extends StatelessWidget {
  const CreationTooSlowView({
    required this.studio,
    required this.onShelf,
    required this.onDone,
    super.key,
  });

  final AvatarStudio studio;
  final VoidCallback? onShelf;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final onShelf = this.onShelf;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CreationEgg(studio: studio, size: NestSize.avatarLarge),
          ),
          const SizedBox(height: NestSpace.lg),
          Text(AvatarCreationCopy.tooSlowTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.sm),
          Semantics(
            liveRegion: true,
            child: Text(AvatarCreationCopy.tooSlowBody, style: nest.text.body),
          ),
          const SizedBox(height: NestSpace.xl),
          if (onShelf != null) ...[
            NestButton(
              label: AvatarCreationCopy.seeShelf,
              icon: LucideIcons.images,
              onPressed: onShelf,
            ),
            const SizedBox(height: NestSpace.sm),
          ],
          NestButton(
            label: AvatarCreationCopy.done,
            variant: onShelf == null
                ? NestButtonVariant.primary
                : NestButtonVariant.outline,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}
