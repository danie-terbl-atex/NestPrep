import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import 'offline_badge.dart';

/// The two V2 things a document's sheet offers (documents ADR-0006,
/// ADR-0007): send it by a link, and keep it on this phone. Each shows only
/// when its switch is on and — for sharing — when this person may share it;
/// the screen decides both and hands this the answers (`FE-03`).
class ShareAndKeepActions extends StatelessWidget {
  const ShareAndKeepActions({
    required this.showsShare,
    required this.showsKeep,
    required this.isKept,
    required this.isSaving,
    required this.onShare,
    required this.onKeep,
    required this.onRemove,
    super.key,
  });

  final bool showsShare;
  final bool showsKeep;

  /// Already on this phone.
  final bool isKept;

  /// Being encrypted and written now.
  final bool isSaving;
  final VoidCallback onShare;
  final VoidCallback onKeep;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showsShare)
          NestButton(
            label: ShareLinkCopy.shareAction,
            icon: LucideIcons.link,
            variant: NestButtonVariant.tonal,
            onPressed: onShare,
          ),
        if (showsShare && showsKeep) const SizedBox(height: NestSpace.sm),
        if (showsKeep && isKept) ...[
          const Align(alignment: Alignment.centerLeft, child: OfflineBadge()),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: OfflineCopiesCopy.remove,
            icon: LucideIcons.smartphone,
            variant: NestButtonVariant.outline,
            onPressed: onRemove,
          ),
        ] else if (showsKeep) ...[
          NestButton(
            label: isSaving ? OfflineCopiesCopy.saving : OfflineCopiesCopy.keep,
            icon: LucideIcons.circleArrowDown,
            variant: NestButtonVariant.outline,
            isLoading: isSaving,
            onPressed: isSaving ? null : onKeep,
          ),
          const SizedBox(height: NestSpace.xs),
          Text(
            OfflineCopiesCopy.keepNote,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
      ],
    );
  }
}
