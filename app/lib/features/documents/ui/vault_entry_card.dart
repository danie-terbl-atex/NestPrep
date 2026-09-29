import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';

/// The way into the personal vaults from Documents. It says whether the vaults
/// are locked, in words and an icon (`FE-13`), and it is on the folder list and
/// on its empty state alike, so it never disappears for a household with no
/// folders yet (`FE-08`).
class VaultEntryCard extends StatelessWidget {
  const VaultEntryCard({
    required this.isUnlocked,
    required this.onOpenVaults,
    super.key,
  });

  final bool isUnlocked;
  final VoidCallback onOpenVaults;

  @override
  Widget build(BuildContext context) {
    final icon = isUnlocked ? Icons.lock_open_outlined : Icons.lock_outline;
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: VaultCopy.entryTitle,
        subtitle: VaultCopy.entryBody,
        leading: NestIconTile(icon: icon, tint: NestTileTint.pink),
        footer: NestBadge(
          label: isUnlocked ? VaultCopy.entryUnlocked : VaultCopy.entryLocked,
          tone: isUnlocked ? NestBadgeTone.info : NestBadgeTone.neutral,
          icon: icon,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpenVaults,
      ),
    );
  }
}
