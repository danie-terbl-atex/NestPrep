import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/language/translated_line.dart';
import '../state/helper_language_controller.dart';
import 'read_aloud_button.dart';
import 'translation_badge.dart';

/// One safety line as the helper reads it (home-care ADR-0006): in her
/// language, **always with the English beneath** — a wrong word here can hurt
/// somebody — badged machine-translated unless a speaker checked it, and read
/// aloud from a button of its own.
class TranslatedSafetyRow extends StatelessWidget {
  const TranslatedSafetyRow({
    required this.icon,
    required this.tone,
    required this.title,
    this.why,
    super.key,
  });

  final IconData icon;
  final NestTagTone tone;
  final String title;
  final String? why;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final language = context.watch<HelperLanguageController>();
    final heading = language.lineFor(title);
    final reason = why == null ? null : language.lineFor(why!);
    final english = [title, ?why].join(' — ');
    final spoken = TranslatedLine(
      english: [title, ?why].join('. '),
      text: [heading.text, ?reason?.text].join('. '),
      source: heading.source,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestToneRow(
          icon: icon,
          tone: tone,
          title: heading.text,
          subtitle: reason?.text,
          trailing: language.isAvailable ? ReadAloudButton(line: spoken) : null,
        ),
        if (heading.isTranslated)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpace.md,
              NestSpace.xs,
              NestSpace.md,
              0,
            ),
            child: Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TranslationBadge(source: heading.source),
                Text(
                  HomeCareLanguageCopy.inEnglish(english),
                  style: nest.text.caption,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The panel's row builder, for `SafetyPanel(rowBuilder: …)`.
Widget translatedSafetyRow({
  required IconData icon,
  required NestTagTone tone,
  required String title,
  String? why,
}) => TranslatedSafetyRow(icon: icon, tone: tone, title: title, why: why);
