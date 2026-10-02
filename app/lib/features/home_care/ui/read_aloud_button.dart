import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/read_aloud.dart';
import '../model/language/translated_line.dart';
import '../state/read_aloud_controller.dart';

/// Reads one line aloud, or stops it — its own button beside the line, so a
/// screen reader meets it as a control of its own (home-care ADR-0006).
/// Absent while the phone has not said whether it can speak, and when it
/// cannot: the language bar says why once, rather than every line.
class ReadAloudButton extends StatelessWidget {
  const ReadAloudButton({required this.line, super.key});

  final TranslatedLine line;

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<ReadAloudController>();
    final support = voice.support;
    if (support == null || support == VoiceSupport.none) {
      return const SizedBox.shrink();
    }
    final isSpeaking = voice.isSpeaking(line);
    return NestIconButton(
      icon: isSpeaking ? LucideIcons.circleStop : LucideIcons.volume2,
      label: isSpeaking
          ? HomeCareLanguageCopy.stopReadingFor(line.text)
          : HomeCareLanguageCopy.readAloudFor(line.text),
      variant: isSpeaking
          ? NestIconButtonVariant.accent
          : NestIconButtonVariant.glass,
      onPressed: () => voice.toggle(line),
    );
  }
}
