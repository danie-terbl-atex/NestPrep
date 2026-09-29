import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/helper_language_controller.dart';
import '../state/read_aloud_controller.dart';

/// What language this screen is in, whether the phone can read it aloud, and
/// the switch to see the English too (home-care ADR-0006). A translation that
/// could not happen is said here once, with a way to try again, while the
/// lines below stay readable in English.
class LanguageBar extends StatelessWidget {
  const LanguageBar({required this.texts, super.key});

  /// The English lines on this screen, asked for again on a retry.
  final List<String> texts;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final language = context.watch<HelperLanguageController>();
    final support = context.watch<ReadAloudController>().support;
    final current = language.language;
    final failure = language.translationFailure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestCard(
          variant: NestCardVariant.tinted,
          padding: const EdgeInsets.all(NestSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const NestIconTile(
                    icon: Icons.translate,
                    tint: NestTileTint.sky,
                    size: NestSize.avatarMedium,
                    iconSize: NestSize.iconMedium,
                  ),
                  const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HomeCareLanguageCopy.showing(current),
                          style: nest.text.bodyStrong,
                        ),
                        if (support != null)
                          Text(
                            HomeCareLanguageCopy.voice(support, current),
                            style: nest.text.caption,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (current.needsTranslation) ...[
                const SizedBox(height: NestSpace.sm),
                Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    NestChip(
                      label: language.showEnglish
                          ? HomeCareLanguageCopy.hideEnglish
                          : HomeCareLanguageCopy.showEnglish,
                      icon: Icons.subtitles_outlined,
                      isSelected: language.showEnglish,
                      onTap: language.toggleEnglish,
                    ),
                    if (language.isTranslating)
                      const NestTag(
                        label: HomeCareLanguageCopy.translating,
                        icon: Icons.hourglass_top,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (failure != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.warning,
            actionLabel: AppCopy.retry,
            onAction: () => language.retryTranslation(texts),
          ),
        ],
      ],
    );
  }
}
