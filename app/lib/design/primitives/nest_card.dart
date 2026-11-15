import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_icon_tile.dart';
import 'nest_pressable.dart';

enum NestCardVariant { raised, flat, tinted }

/// A surface. Raised sits on the page with a warm glow; flat is a bordered
/// panel inside another surface; tinted is the selected or tonal panel. A
/// tappable card settles under the finger. With a [tint] it is filled in one
/// of the brand's accents instead, for a card that is a picture as much as
/// a panel; what sits on it is drawn in Ink, the one ink the contrast test
/// holds to AA on every tint. It owns its inner padding and nothing outside
/// its box (`FE-03`).
class NestCard extends StatelessWidget {
  const NestCard({
    required this.child,
    this.variant = NestCardVariant.raised,
    this.padding = const EdgeInsets.all(NestSpace.xl),
    this.tint,
    this.onTap,
    super.key,
  });

  final Widget child;
  final NestCardVariant variant;
  final EdgeInsetsGeometry padding;
  final NestTileTint? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final (fill, shadows) = switch (variant) {
      NestCardVariant.raised => (c.surface, nest.shadows.card),
      NestCardVariant.flat => (c.surface, const <BoxShadow>[]),
      NestCardVariant.tinted => (c.surfaceTint, const <BoxShadow>[]),
    };
    final color = switch (tint) {
      null => fill,
      NestTileTint.accent => c.accentSoft,
      NestTileTint.guava => c.tileGuava,
      NestTileTint.basil => c.tileBasil,
      NestTileTint.lilac => c.tileLilac,
      NestTileTint.butter => c.tileButter,
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NestRadius.xl),
      side: tint == null ? BorderSide(color: c.outline) : BorderSide.none,
    );
    final card = DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: shadows),
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? card : NestPressable(child: card);
  }
}
