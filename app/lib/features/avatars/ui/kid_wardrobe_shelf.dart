import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../../household/model/member.dart';
import 'member_avatar.dart';

class KidWardrobeShelf extends StatelessWidget {
  const KidWardrobeShelf({
    required this.me,
    required this.shopIsOpen,
    required this.onOpen,
    super.key,
  });

  final Member me;
  final bool shopIsOpen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: AvatarCopy.kidShelfTitle),
        const SizedBox(height: NestSpace.sm),
        NestCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: NestSize.avatarLarge * NestAvatar.topOverhang,
                    ),
                    child: MemberAvatar(member: me, size: NestSize.avatarLarge),
                  ),
                  const SizedBox(width: NestSpace.lg),
                  Expanded(
                    child: Text(
                      shopIsOpen
                          ? AvatarCopy.kidShelfBody
                          : AvatarCopy.kidShelfClosedBody,
                      style: nest.text.body,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NestSpace.md),
              NestButton(
                label: AvatarCopy.kidShelfAction,
                icon: LucideIcons.shirt,
                variant: NestButtonVariant.tonal,
                onPressed: onOpen,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
