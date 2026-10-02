import 'package:flutter/widgets.dart';

import '../tokens/nest_theme.dart';

/// The short spaced label over a heading: "Your week, a little lighter".
/// Upper-cased here so the copy file stays in sentence case.
class NestEyebrow extends StatelessWidget {
  const NestEyebrow(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Text(
        text.toUpperCase(),
        style: nest.text.eyebrow.copyWith(color: color),
      ),
    );
  }
}
