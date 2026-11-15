import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/member_role.dart';

/// The people a household usually invites, each suggesting the role they
/// usually hold: a partner manages the household too, a grandparent is family
/// without managing it, and helpers and carers see what a parent chooses
/// (household ADR-0003). The sheet that follows lets the role be changed.
class InviteOptionList extends StatelessWidget {
  const InviteOptionList({
    required this.onChoose,
    this.isLocked = false,
    super.key,
  });

  final ValueChanged<MemberRole> onChoose;

  /// The free plan is full (subscriptions ADR-0008): every option stays, with
  /// a lock, and choosing one is the caller's to answer with the paywall.
  final bool isLocked;

  static const _options = [
    (
      AccessCopy.setupPartner,
      LucideIcons.heart,
      NestTileTint.guava,
      MemberRole.admin,
    ),
    (
      AccessCopy.setupGrandparent,
      LucideIcons.personStanding,
      NestTileTint.butter,
      MemberRole.parent,
    ),
    (
      AccessCopy.setupHelper,
      LucideIcons.sprayCan,
      NestTileTint.lilac,
      MemberRole.helper,
    ),
    (
      AccessCopy.setupCarer,
      LucideIcons.baby,
      NestTileTint.basil,
      MemberRole.carer,
    ),
    (
      AccessCopy.setupChild,
      LucideIcons.smartphone,
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
                    isLocked ? LucideIcons.lock : LucideIcons.circlePlus,
                    size: NestSize.iconMedium,
                    color: nest.colors.accentInk,
                    semanticLabel: isLocked
                        ? SubscriptionCopy.lockedHint
                        : null,
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
