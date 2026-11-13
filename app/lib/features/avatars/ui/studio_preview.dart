import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../model/avatar_base.dart';
import '../model/avatar_studio.dart';
import 'member_avatar.dart';

class StudioPreview extends StatelessWidget {
  const StudioPreview({
    required this.studio,
    required this.isSelf,
    required this.onUseInitial,
    super.key,
  });

  final AvatarStudio studio;
  final bool isSelf;
  final VoidCallback onUseInitial;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final member = studio.member;
    final nestling = switch (studio.preview.base) {
      PresetBase(:final name) => studio.library.nestling(name)?.label,
      _ => null,
    };
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: NestSize.avatarHero * NestAvatar.topOverhang,
            ),
            child: MemberAvatar(
              member: member,
              look: studio.preview,
              size: NestSize.avatarHero,
            ),
          ),
          const SizedBox(height: NestSpace.md),
          Text(
            member.displayName,
            textAlign: TextAlign.center,
            style: nest.text.headline,
          ),
          if (nestling != null)
            Text(
              AvatarCopy.nestlingAt(nestling, studio.stage),
              textAlign: TextAlign.center,
              style: nest.text.bodySecondary,
            ),
          if (!studio.usesInitial) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: isSelf
                  ? AvatarCopy.useMyInitial
                  : AvatarCopy.useInitialOf(member.displayName),
              icon: LucideIcons.undo2,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: onUseInitial,
            ),
          ],
        ],
      ),
    );
  }
}
