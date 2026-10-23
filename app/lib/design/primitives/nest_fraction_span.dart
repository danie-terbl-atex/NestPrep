import 'package:flutter/widgets.dart';

/// [text] in [style] with every `n/d` in it set as a kitchen fraction — a
/// small raised numerator, the fraction slash, a small denominator — so
/// `1 1/3 cups` reads as a cook writes it, in the app's own face.
///
/// The bundled DM Sans is subset: it carries ½ ¼ ¾ but not ⅓ ⅔ ⅛, and its
/// `frac` feature knows only those three. Drawing every fraction this way
/// keeps a third looking like a half, rather than one glyph from the font
/// and another from whatever the phone falls back to. It grows with the text
/// setting like the words around it (`FE-13`). A screen reader is given the
/// words by the widget that uses it.
InlineSpan nestFractionSpan(String text, TextStyle style) {
  final children = <InlineSpan>[];
  var from = 0;
  for (final match in _fraction.allMatches(text)) {
    final before = text.substring(from, match.start);
    // `1 1/3`: the whole number sits against its fraction, as on a recipe.
    final joined = before.endsWith(' ') && _endsInDigit.hasMatch(before)
        ? before.substring(0, before.length - 1)
        : before;
    if (joined.isNotEmpty) children.add(TextSpan(text: joined));
    children.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: _Fraction(
          numerator: match.group(1)!,
          denominator: match.group(2)!,
          style: style,
        ),
      ),
    );
    from = match.end;
  }
  if (from < text.length) children.add(TextSpan(text: text.substring(from)));
  return TextSpan(style: style, children: children);
}

final _fraction = RegExp(r'(\d+)/(\d+)');
final _endsInDigit = RegExp(r'\d $');

/// How the parts of a fraction sit against the text: the figures at about
/// three fifths of its size, the numerator lifted by a third of it.
const _figureScale = 0.62;

/// The fraction slash, which the bundled face has, rather than a solidus.
const _slash = '\u2044';
const _lift = 0.34;

class _Fraction extends StatelessWidget {
  const _Fraction({
    required this.numerator,
    required this.denominator,
    required this.style,
  });

  final String numerator;
  final String denominator;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? DefaultTextStyle.of(context).style.fontSize;
    final em = MediaQuery.textScalerOf(context).scale(size ?? 0);
    final small = style.copyWith(
      fontSize: (size ?? 0) * _figureScale,
      height: 1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Transform.translate(
          offset: Offset(0, -em * _lift),
          child: Text(numerator, style: small),
        ),
        Text(_slash, style: style.copyWith(height: 1)),
        Text(denominator, style: small),
      ],
    );
  }
}
