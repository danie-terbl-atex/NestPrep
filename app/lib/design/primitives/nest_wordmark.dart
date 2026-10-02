import 'package:flutter/widgets.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_brand_mark.dart';

/// "nestprep" set tight in Fraunces (design-system ADR-0008). Read once, as a
/// heading, under [semanticsLabel].
class NestWordmark extends StatelessWidget {
  const NestWordmark({
    required this.semanticsLabel,
    this.size = NestSize.wordmarkLarge,
    super.key,
  });

  final String semanticsLabel;
  final double size;

  static const _letters = 'nestprep';

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      label: semanticsLabel,
      header: true,
      excludeSemantics: true,
      child: Text(
        _letters,
        textScaler: TextScaler.noScaling,
        style: nest.text.display.copyWith(
          fontSize: size,
          height: 1,
          letterSpacing: -size * 0.04,
          color: nest.colors.ink,
          fontVariations: [FontVariation('opsz', size)],
        ),
      ),
    );
  }
}

/// The mark beside the wordmark, as the brand board sets them.
class NestBrandLockup extends StatelessWidget {
  const NestBrandLockup({
    required this.semanticsLabel,
    this.size = NestSize.wordmarkSmall,
    super.key,
  });

  final String semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NestBrandMark(size: size * 1.25),
        SizedBox(width: size * 0.35),
        NestWordmark(semanticsLabel: semanticsLabel, size: size),
      ],
    );
  }
}
