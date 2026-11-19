import 'package:flutter/widgets.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A short line said by whoever stands at its start (Twig, design-system
/// ADR-0026): a bubble whose corner nearest the speaker is pinched, so it
/// reads as speech without a tail to lay out. The words are the caller's.
class NestSaying extends StatelessWidget {
  const NestSaying(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: nest.colors.surface,
        border: Border.all(color: nest.colors.outline),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(NestRadius.xs),
          topRight: Radius.circular(NestRadius.xl),
          bottomLeft: Radius.circular(NestRadius.xl),
          bottomRight: Radius.circular(NestRadius.xl),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NestSpace.md),
        child: Text(text, style: nest.text.body),
      ),
    );
  }
}
