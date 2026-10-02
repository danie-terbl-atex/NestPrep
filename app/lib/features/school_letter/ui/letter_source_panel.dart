import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/letter_picker.dart';

/// The way in: what snapping a letter does, the three places a letter comes
/// from, and — before anything is picked — what leaves the phone and what
/// does not (foundation ADR-0015's POPIA section, said in plain words).
///
/// A read that failed comes back here with its reason above the choices, so
/// the way to try again is never taken away (`FE-08`).
class LetterSourcePanel extends StatelessWidget {
  const LetterSourcePanel({
    required this.onPick,
    this.failure,
    this.onRetry,
    super.key,
  });

  final ValueChanged<LetterSource> onPick;
  final AppFailure? failure;

  /// Send the same letter again; null when there is nothing to resend.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final shown = failure;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (shown != null) ...[
          // The retry is a button of its own below the banner rather than
          // the banner's action: at 200% text a banner action this long
          // pushes past a 360-wide phone (`FE-14`).
          NestBanner(
            message: AppCopy.failure(shown),
            tone: NestBannerTone.danger,
          ),
          const SizedBox(height: NestSpace.sm),
          if (onRetry case final retry?)
            NestButton(
              label: SchoolLetterCopy.tryAgain,
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
                const NestIconTile(
                  icon: LucideIcons.scanText,
                  tint: NestTileTint.lilac,
                ),
                const SizedBox(height: NestSpace.md),
                Text(
                  SchoolLetterCopy.heroTitle,
                  style: nest.text.title.copyWith(color: nest.colors.ink),
                ),
                const SizedBox(height: NestSpace.sm),
                Text(
                  SchoolLetterCopy.heroBody,
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
                label: SchoolLetterCopy.takePhoto,
                icon: LucideIcons.camera,
                onPressed: () => onPick(LetterSource.camera),
              ),
              const SizedBox(height: NestSpace.sm),
              NestButton(
                label: SchoolLetterCopy.choosePhoto,
                icon: LucideIcons.images,
                variant: NestButtonVariant.tonal,
                onPressed: () => onPick(LetterSource.photos),
              ),
              const SizedBox(height: NestSpace.sm),
              NestButton(
                label: SchoolLetterCopy.choosePdf,
                icon: LucideIcons.fileText,
                variant: NestButtonVariant.outline,
                onPressed: () => onPick(LetterSource.pdf),
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        const NestRiseIn(
          index: 2,
          child: NestToneRow(
            icon: LucideIcons.lock,
            title: SchoolLetterCopy.privacyTitle,
            subtitle: SchoolLetterCopy.privacyBody,
          ),
        ),
      ],
    );
  }
}
