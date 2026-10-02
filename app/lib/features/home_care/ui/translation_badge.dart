import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/language/translated_line.dart';

/// Where a translation came from, in words and not only colour (`FE-13`):
/// a machine's, or checked by somebody who speaks the language (home-care
/// ADR-0006). Nothing for English.
class TranslationBadge extends StatelessWidget {
  const TranslationBadge({required this.source, super.key});

  final TranslationSource source;

  @override
  Widget build(BuildContext context) => switch (source) {
    TranslationSource.english => const SizedBox.shrink(),
    TranslationSource.machine => const NestTag(
      label: HomeCareLanguageCopy.machineTranslated,
      icon: LucideIcons.languages,
    ),
    TranslationSource.reviewed => const NestTag(
      label: HomeCareLanguageCopy.reviewed,
      icon: LucideIcons.badgeCheck,
      tone: NestTagTone.success,
    ),
  };
}
