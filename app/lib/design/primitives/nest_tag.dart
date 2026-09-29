import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

enum NestTagTone { neutral, accent, success, warning, danger }

/// A small, non-interactive label pill: a status, a rule, a warning — "Severe",
/// "Nut-free", "School rule". Where `NestChip` is something to tap, a tag is
/// something to read.
///
/// The tone is never the only signal: the label says it, and an optional icon
/// says it again (`FE-13`). Every tone is one of the soft pairs the contrast
/// test already proves at AA in both themes.
class NestTag extends StatelessWidget {
  const NestTag({
    required this.label,
    this.tone = NestTagTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final NestTagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final (fill, ink) = switch (tone) {
      NestTagTone.neutral => (c.surfaceTint, c.ink),
      NestTagTone.accent => (c.accentSoft, c.accentInk),
      NestTagTone.success => (c.successSoft, c.success),
      NestTagTone.warning => (c.warningSoft, c.warning),
      NestTagTone.danger => (c.dangerSoft, c.danger),
    };
    final glyph = icon;
    return DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NestSpace.md,
          vertical: NestSpace.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              Icon(glyph, size: NestSize.iconSmall, color: ink),
              const SizedBox(width: NestSpace.xs),
            ],
            // A tag sits in a wrap beside others and grows with the text
            // setting, so its label yields rather than overflowing (`FE-13`).
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nest.text.label.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
