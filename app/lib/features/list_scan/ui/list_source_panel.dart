import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/list_photo_picker.dart';

/// The way in: what snapping a list does, where the photo comes from, and —
/// before anything is picked — what leaves the phone. A read that failed
/// comes back here with its reason, so trying again is never taken away
/// (`FE-08`); Twig welcomes only a fresh start (design-system ADR-0012).
class ListSourcePanel extends StatelessWidget {
  const ListSourcePanel({
    required this.onPick,
    required this.isAiWelcome,
    this.failure,
    this.onRetry,
    super.key,
  });

  final ValueChanged<ListPhotoSource> onPick;
  final bool isAiWelcome;
  final AppFailure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final shown = failure;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (shown != null) ...[
          NestBanner(
            message: AppCopy.failure(shown),
            tone: NestBannerTone.danger,
          ),
          const SizedBox(height: NestSpace.sm),
          if (onRetry case final retry?)
            NestButton(
              label: ListScanCopy.tryAgain,
              icon: LucideIcons.refreshCw,
              variant: NestButtonVariant.tonal,
              onPressed: retry,
            ),
          const SizedBox(height: NestSpace.lg),
        ],
        NestRiseIn(
          child: NestCard(
            variant: NestCardVariant.tinted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAiWelcome)
                  const NestTwig(
                    pose: NestTwigPose.welcome,
                    size: NestSize.twigLarge,
                  )
                else
                  const NestIconTile(
                    icon: LucideIcons.scanText,
                    tint: NestTileTint.basil,
                  ),
                const SizedBox(height: NestSpace.md),
                Text(
                  ListScanCopy.heroTitle,
                  style: nest.text.title.copyWith(color: nest.colors.ink),
                ),
                const SizedBox(height: NestSpace.sm),
                Text(
                  ListScanCopy.heroBody,
                  style: nest.text.body.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NestButton(
                key: const ValueKey('list-scan-camera'),
                label: ListScanCopy.takePhoto,
                icon: LucideIcons.camera,
                onPressed: () => onPick(ListPhotoSource.camera),
              ),
              const SizedBox(height: NestSpace.sm),
              NestButton(
                key: const ValueKey('list-scan-photos'),
                label: ListScanCopy.choosePhoto,
                icon: LucideIcons.images,
                variant: NestButtonVariant.tonal,
                onPressed: () => onPick(ListPhotoSource.photos),
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        const NestRiseIn(
          index: 2,
          child: NestToneRow(
            icon: LucideIcons.lock,
            title: ListScanCopy.privacyTitle,
            subtitle: ListScanCopy.privacyBody,
          ),
        ),
      ],
    );
  }
}
