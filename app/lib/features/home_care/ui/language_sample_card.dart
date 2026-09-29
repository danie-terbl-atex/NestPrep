import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/helper_language_controller.dart';
import '../state/read_aloud_controller.dart';
import 'read_aloud_button.dart';
import 'translation_badge.dart';

/// One line in the chosen language, to read and to hear — so she knows what
/// her jobs will look like and whether her phone can speak them before the
/// first one arrives (home-care ADR-0006).
class LanguageSampleCard extends StatelessWidget {
  const LanguageSampleCard({super.key});

  static const _sample = [HomeCareLanguageCopy.sampleLine];

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final language = context.watch<HelperLanguageController>();
    final support = context.watch<ReadAloudController>().support;
    language.ensure(_sample);
    final line = language.lineFor(HomeCareLanguageCopy.sampleLine);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(HomeCareLanguageCopy.tryItHeading, style: nest.text.label),
          const SizedBox(height: NestSpace.sm),
          Row(
            children: [
              Expanded(child: Text(line.text, style: nest.text.title)),
              const SizedBox(width: NestSpace.sm),
              ReadAloudButton(line: line),
            ],
          ),
          if (line.isTranslated) ...[
            const SizedBox(height: NestSpace.xs),
            Text(
              HomeCareLanguageCopy.inEnglish(line.english),
              style: nest.text.caption,
            ),
            const SizedBox(height: NestSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TranslationBadge(source: line.source),
            ),
          ],
          if (language.isTranslating) ...[
            const SizedBox(height: NestSpace.sm),
            Text(HomeCareLanguageCopy.translating, style: nest.text.caption),
          ],
          if (support != null) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              HomeCareLanguageCopy.voice(support, language.language),
              style: nest.text.caption,
            ),
          ],
        ],
      ),
    );
  }
}
