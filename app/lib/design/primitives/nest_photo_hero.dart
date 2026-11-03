import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_icon_button.dart';
import 'nest_photo.dart';

/// The top of a page that opens on a photograph — a recipe: the picture
/// edge to edge and under the status bar at a fixed [aspectRatio], so
/// nothing moves when it arrives (`FE-18`); a soft scrim at the top that
/// keeps the status bar's light icons and the back button legible on any
/// photo; and the page's own canvas lifting over its foot in a round lip,
/// so what follows reads as a sheet laid on the picture
/// (design-system ADR-0008).
///
/// The back button is a glass disc — Oat over the photo — and always there:
/// what it does is the page's to decide (`FE-17`).
class NestPhotoHero extends StatelessWidget {
  const NestPhotoHero({
    required this.photo,
    required this.backLabel,
    required this.onBack,
    this.aspectRatio = 4 / 3,
    this.semanticsLabel,
    this.heroTag,
    super.key,
  });

  final Widget photo;
  final String backLabel;
  final VoidCallback onBack;
  final double aspectRatio;

  /// What the photo shows, for somebody who cannot see it; null when it is
  /// decoration beside a heading that already says it.
  final String? semanticsLabel;

  /// The tag of the card this page was opened from: the photo flies from it
  /// to the page's edges, its corners squaring on the way.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: NestPhotoFrame(
              heroTag: heroTag,
              radius: 0,
              semanticsLabel: semanticsLabel,
              child: photo,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + NestSize.touchTarget + NestSpace.xl,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.scrim, c.scrim.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -NestStroke.hairline,
            height: NestRadius.xxl,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.canvas,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(NestRadius.xxl),
                ),
              ),
            ),
          ),
          Positioned(
            left: NestSpace.lg,
            top: top + NestSpace.sm,
            child: NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: backLabel,
              onPressed: onBack,
            ),
          ),
        ],
      ),
    );
  }
}
