import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../state/helper_language_controller.dart';
import 'big_step_tile.dart';
import 'read_aloud_button.dart';

/// A step or a routine's item as the helper reads it: in her language, big
/// enough to tick with gloves on, the English beneath when she asked for it,
/// and a button beside it that reads it aloud (home-care ADR-0006).
class TranslatedStepTile extends StatelessWidget {
  const TranslatedStepTile({
    required this.number,
    required this.english,
    required this.isDone,
    required this.onToggle,
    super.key,
  });

  final int number;

  /// The step as the parent wrote it.
  final String english;
  final bool isDone;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<HelperLanguageController>();
    final line = language.lineFor(english);
    return Row(
      children: [
        Expanded(
          child: BigStepTile(
            number: number,
            text: line.text,
            english: line.isTranslated && language.showEnglish
                ? line.english
                : null,
            isDone: isDone,
            onToggle: onToggle,
          ),
        ),
        if (language.isAvailable) ...[
          const SizedBox(width: NestSpace.xs),
          ReadAloudButton(line: line),
        ],
      ],
    );
  }
}
