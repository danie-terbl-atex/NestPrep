import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// How loudly a badge speaks. The same four tones as a banner, so a status
/// means the same colour everywhere it appears.
enum NestBadgeTone { neutral, info, warning, danger }

/// A small status pill beside a row's title — "Expires in 12 days",
/// "Expired". Always an icon and words together, never a colour alone
/// (`FE-13`); the pairs are the banner's, which the contrast test already
/// proves in both themes.
class NestBadge extends StatelessWidget {
  const NestBadge({
    required this.label,
    this.tone = NestBadgeTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final NestBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final (fill, ink) = switch (tone) {
      NestBadgeTone.neutral => (c.surfaceTint, c.inkSecondary),
      NestBadgeTone.info => (c.accentSoft, c.accentInk),
      NestBadgeTone.warning => (c.warningSoft, c.warning),
      NestBadgeTone.danger => (c.dangerSoft, c.danger),
    };
    final glyph = icon;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(NestRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NestSpace.sm,
            vertical: NestSpace.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (glyph != null) ...[
                Icon(glyph, size: NestSize.iconBadge, color: ink),
                const SizedBox(width: NestSpace.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nest.text.caption.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
