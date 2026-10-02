import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

enum NestLogoTileTone { idle, selected, muted }

/// Somebody else's mark — a shop's logo — as a small rounded square, drawn in
/// its own colours and never recoloured, with a hairline so a black or white
/// logo still has an edge in either theme.
///
/// [NestLogoTileTone.selected] adds a ring and a tick, so the choice is a
/// shape as well as a colour; [NestLogoTileTone.muted] draws it in grey, for
/// something not available yet — the caller says why in words beside it
/// (`FE-13`). Tappable when [onTap] is given, always at the touch-target
/// floor however small the logo is drawn.
class NestLogoTile extends StatelessWidget {
  const NestLogoTile({
    required this.asset,
    required this.label,
    this.onTap,
    this.size = NestSize.logoSmall,
    this.tone = NestLogoTileTone.idle,
    super.key,
  });

  /// A square image under `assets/`.
  final String asset;

  /// What a screen reader says, and the tooltip.
  final String label;
  final VoidCallback? onTap;
  final double size;
  final NestLogoTileTone tone;

  /// Grey alone leaves a black-and-white logo looking chosen-able, so a muted
  /// one is faded as well.
  static const _mutedOpacity = 0.4;

  static const _greyscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final isSelected = tone == NestLogoTileTone.selected;
    const radius = BorderRadius.all(Radius.circular(NestRadius.xs));
    Widget logo = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    );
    if (tone == NestLogoTileTone.muted) {
      logo = Opacity(
        opacity: _mutedOpacity,
        child: ColorFiltered(colorFilter: _greyscale, child: logo),
      );
    }
    final tile = AnimatedContainer(
      duration: NestMotion.of(context).quick,
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: isSelected ? c.secondary : c.outline,
          width: isSelected ? NestStroke.focus : NestStroke.hairline,
        ),
      ),
      child: ClipRRect(borderRadius: radius, child: logo),
    );
    final extent = size < NestSize.touchTarget ? NestSize.touchTarget : size;
    return Semantics(
      container: true,
      button: onTap != null,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: extent,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  tile,
                  if (isSelected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: NestSize.iconSmall,
                          color: c.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
