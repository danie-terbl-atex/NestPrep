import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/member_role.dart';

/// The people a household usually invites, each suggesting the role they
/// usually hold: a partner manages the household too, a grandparent is family
/// without managing it, and helpers and carers see what a parent chooses
/// (household ADR-0003). The sheet that follows lets the role be changed.
class InviteOptionList extends StatelessWidget {
  const InviteOptionList({required this.onChoose, super.key});

  final ValueChanged<MemberRole> onChoose;

  static const _options = [
    (
      AccessCopy.setupPartner,
      Icons.favorite_outline,
      NestTileTint.guava,
      MemberRole.admin,
    ),
    (
      AccessCopy.setupGrandparent,
      Icons.elderly_outlined,
      NestTileTint.butter,
      MemberRole.parent,
    ),
    (
      AccessCopy.setupHelper,
      Icons.cleaning_services_outlined,
      NestTileTint.lilac,
      MemberRole.helper,
    ),
    (
      AccessCopy.setupCarer,
      Icons.child_care_outlined,
      NestTileTint.basil,
      MemberRole.carer,
    ),
    (
      AccessCopy.setupChild,
      Icons.smartphone_outlined,
      NestTileTint.accent,
      MemberRole.kid,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, (label, icon, tint, role)) in _options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestRiseIn(
              index: 1 + index,
              child: NestCard(
                variant: NestCardVariant.flat,
                padding: EdgeInsets.zero,
                child: NestListRow(
                  leading: NestIconTile(icon: icon, tint: tint),
                  title: label,
                  subtitle: AccessCopy.setupJoinsAs(role),
                  trailing: Icon(
                    Icons.add_circle_outline,
                    size: NestSize.iconMedium,
                    color: nest.colors.accentInk,
                  ),
                  onTap: () => onChoose(role),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
