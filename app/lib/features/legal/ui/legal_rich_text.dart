import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/legal_span.dart';

/// One run of a legal document's inline text: bold where it is bold, a link
/// in the accent and underlined (never colour alone, `FE-13`), and a draft's
/// placeholder on a warning fill, read aloud as the gap it is.
///
/// Stateful only to own the tap recognisers its links need — a recogniser
/// that is not disposed outlives the text it was for.
class LegalRichText extends StatefulWidget {
  const LegalRichText({
    required this.spans,
    required this.style,
    required this.onOpenLink,
    super.key,
  });

  final List<LegalSpan> spans;
  final TextStyle style;
  final ValueChanged<Uri> onOpenLink;

  @override
  State<LegalRichText> createState() => _LegalRichTextState();
}

class _LegalRichTextState extends State<LegalRichText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final c = NestTheme.of(context).colors;
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [for (final span in widget.spans) _textSpanOf(span, c)],
      ),
    );
  }

  TextSpan _textSpanOf(LegalSpan span, NestColors c) {
    final weight = span.isBold ? FontWeight.w700 : null;
    return switch (span) {
      LegalText() => TextSpan(
        text: span.text,
        style: TextStyle(fontWeight: weight),
      ),
      LegalLink(:final target) => TextSpan(
        text: span.text,
        style: TextStyle(
          fontWeight: weight,
          color: c.accentInk,
          decoration: TextDecoration.underline,
          decorationColor: c.accentInk,
        ),
        recognizer: _recognizerFor(target),
      ),
      LegalPlaceholder() => TextSpan(
        text: '[${span.text}]',
        semanticsLabel: LegalCopy.placeholder(span.text),
        style: TextStyle(
          fontWeight: weight,
          color: c.warning,
          backgroundColor: c.warningSoft,
        ),
      ),
    };
  }

  TapGestureRecognizer _recognizerFor(Uri target) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onOpenLink(target);
    _recognizers.add(recognizer);
    return recognizer;
  }
}
