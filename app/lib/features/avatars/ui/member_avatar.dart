import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../household/model/member.dart';
import '../model/member_look.dart';
import 'avatar_place_of.dart';
import 'resolved_avatar_of.dart';
import 'resolved_member_avatar.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    required this.member,
    this.size = NestSize.avatarMedium,
    this.highlighted = false,
    this.look,
    super.key,
  });

  final Member member;
  final double size;
  final bool highlighted;
  final MemberLook? look;

  @override
  Widget build(BuildContext context) {
    final avatar = resolvedAvatarOf(context, member, look: look);
    if (avatar == null) {
      return NestAvatar(
        name: member.displayName,
        color: member.color,
        size: size,
        isHighlighted: highlighted,
      );
    }
    return ResolvedMemberAvatar(
      name: member.displayName,
      color: member.color,
      size: size,
      highlighted: highlighted,
      householdId: avatarPlaceOf(context)?.householdId,
      memberId: member.id,
      avatar: avatar,
    );
  }
}
