import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';

/// The export, on the phone and ready: say so, offer the share sheet, and
/// say plainly if the sheet would not open (accounts ADR-0006).
class ExportReadyCard extends StatelessWidget {
  const ExportReadyCard({
    required this.fileCount,
    required this.isSharing,
    required this.onShare,
    required this.onPrepareAgain,
    this.shareFailure,
    super.key,
  });

  final int fileCount;
  final bool isSharing;
  final AppFailure? shareFailure;
  final VoidCallback onShare;
  final VoidCallback onPrepareAgain;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final failure = shareFailure;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestIconTile(
                icon: LucideIcons.circleCheckBig,
                tint: NestTileTint.basil,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Text(
                  AccountDataCopy.exportReadyTitle,
                  style: nest.text.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            AccountDataCopy.exportReadyBody(fileCount),
            style: nest.text.bodySecondary,
          ),
          if (failure != null) ...[
            const SizedBox(height: NestSpace.md),
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.warning,
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: AccountDataCopy.exportShare,
            icon: LucideIcons.share,
            isLoading: isSharing,
            onPressed: isSharing ? null : onShare,
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: AccountDataCopy.exportAgain,
            variant: NestButtonVariant.ghost,
            onPressed: isSharing ? null : onPrepareAgain,
          ),
        ],
      ),
    );
  }
}
