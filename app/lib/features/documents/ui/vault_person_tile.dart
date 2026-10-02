import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../household/model/member.dart';

/// One person's vault on the vault home: their mark and name, how much is in
/// it, and — for the vaults this person manages — how widely it is shared. A
/// badge says when something in it needs renewing.
class VaultPersonTile extends StatelessWidget {
  const VaultPersonTile({
    required this.member,
    required this.count,
    required this.needsAttention,
    required this.onOpen,
    this.sharedWith,
    super.key,
  });

  final Member member;
  final int count;

  /// How many of its documents are expired or expiring soon.
  final int needsAttention;

  /// How many people besides the owner and the admins can read it, when the
  /// viewer manages it; null when that is not theirs to know.
  final int? sharedWith;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final shared = sharedWith;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: VaultCopy.vaultOf(member.displayName),
        subtitle: [
          AppCopy.documentsInFolder(count),
          if (shared != null) VaultCopy.sharedWith(shared),
        ].join(' · '),
        leading: NestAvatar(
          name: member.displayName,
          color: member.color,
          size: NestSize.avatarLarge,
        ),
        footer: needsAttention == 0
            ? null
            : NestBadge(
                label: '${VaultCopy.expiringTitle} · $needsAttention',
                tone: NestBadgeTone.warning,
                icon: LucideIcons.clock,
              ),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: onOpen,
      ),
    );
  }
}
