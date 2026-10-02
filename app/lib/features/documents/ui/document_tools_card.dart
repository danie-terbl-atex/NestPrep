import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The ways into Shared links and Offline copies from Documents (documents
/// ADR-0006, ADR-0007) — each only when its switch is on, beside the vault
/// card and above any empty state, so a household with no folders still
/// reaches them (`FE-08`).
class DocumentToolsCard extends StatelessWidget {
  const DocumentToolsCard({
    required this.showsShares,
    required this.showsOffline,
    required this.onOpenShares,
    required this.onOpenOffline,
    super.key,
  });

  final bool showsShares;
  final bool showsOffline;
  final VoidCallback onOpenShares;
  final VoidCallback onOpenOffline;

  @override
  Widget build(BuildContext context) {
    if (!showsShares && !showsOffline) return const SizedBox.shrink();
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (showsShares)
            NestListRow(
              title: ShareLinkCopy.listEntry,
              subtitle: ShareLinkCopy.listEntryBody,
              leading: const NestIconTile(
                icon: LucideIcons.link,
                tint: NestTileTint.lilac,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: onOpenShares,
            ),
          if (showsOffline)
            NestListRow(
              title: OfflineCopiesCopy.entry,
              subtitle: OfflineCopiesCopy.entryBody,
              leading: const NestIconTile(
                icon: LucideIcons.circleCheck,
                tint: NestTileTint.basil,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: onOpenOffline,
            ),
        ],
      ),
    );
  }
}
