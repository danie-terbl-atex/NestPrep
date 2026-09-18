import 'package:flutter/widgets.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A line that types itself out, once, then rests with the whole sentence on
/// screen and the caret gone.
///
/// The sentence is **always all there**: the part not yet typed is laid out in
/// the same span, painted transparent. That is what makes it honest rather
/// than clever —
///
/// * nothing below shuffles upward as the line grows, and a wrap at 200% text
///   is decided once instead of every frame (`FE-14`);
/// * a screen reader is handed the finished sentence from the first frame,
///   because reading a line out one character at a time is unusable (`FE-13`);
/// * a test that looks for the words finds them, and finds exactly one of
///   them — an invisible second copy to reserve the space would be two.
///
/// And it ends. Under reduce-motion it is simply the finished line on the
/// first frame, and the caret never blinks: a blink is motion with nothing to
/// say, and it would stop the screen ever settling (`FE-15`).
class NestTypewriterText extends StatefulWidget {
  const NestTypewriterText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  State<NestTypewriterText> createState() => _NestTypewriterTextState();
}

class _NestTypewriterTextState extends State<NestTypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _hasStarted = false;

  int get _length => widget.text.characters.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    final typing = NestMotion.of(context).tick * _length;
    if (typing == Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller
      ..duration = typing
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.text,
    excludeSemantics: true,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final typed = (_length * _controller.value).round();
        return _TypedLine(
          done: widget.text.characters.take(typed).toString(),
          toCome: widget.text.characters.skip(typed).toString(),
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    ),
  );
}

/// One line: the whole sentence laid out, with the part still to come painted
/// in nothing, and the caret drawn over the character it has reached.
///
/// The caret is **painted, not spanned**. A `WidgetSpan` caret puts a
/// placeholder character into the line, and from then on the widget's plain
/// text is no longer the sentence — every `find.text` for it stops matching
/// and so, more importantly, does anything else that reads the line back.
class _TypedLine extends StatelessWidget {
  const _TypedLine({
    required this.done,
    required this.toCome,
    required this.style,
    required this.textAlign,
  });

  final String done;
  final String toCome;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    // Invisible, not a colour: the ink the line is already in, at zero alpha.
    // A literal would be the one hex outside `nest_colors.dart` (`FE-02`).
    final unseen = (style.color ?? nest.colors.ink).withValues(alpha: 0);
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    return CustomPaint(
      foregroundPainter: toCome.isEmpty
          ? null
          : _CaretPainter(
              sentence: done + toCome,
              reached: done.length,
              style: resolved,
              textAlign: textAlign,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              color: nest.colors.accent,
            ),
      child: Text.rich(
        TextSpan(
          text: done,
          children: [
            TextSpan(
              text: toCome,
              style: TextStyle(color: unseen),
            ),
          ],
        ),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// Draws the caret where the typing has got to, by laying the sentence out the
/// same way the [Text] above it does and asking where that character sits.
class _CaretPainter extends CustomPainter {
  const _CaretPainter({
    required this.sentence,
    required this.reached,
    required this.style,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.color,
  });

  final String sentence;
  final int reached;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: sentence, style: style),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: size.width);
    final at = painter.getOffsetForCaret(
      TextPosition(offset: reached),
      Rect.zero,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        at.dx,
        at.dy,
        NestStroke.focus,
        painter.preferredLineHeight,
      ),
      Paint()..color = color,
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(_CaretPainter old) =>
      old.reached != reached ||
      old.sentence != sentence ||
      old.color != color ||
      old.textScaler != textScaler;
}
