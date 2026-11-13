import 'package:flutter/material.dart';

import '../tokens/nest_member_palette.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

enum NestAvatarSlot { ring, face, top, badge }

@immutable
class NestAvatarLayer {
  const NestAvatarLayer({
    required this.slot,
    required this.image,
    this.centre,
    this.width,
  });

  final NestAvatarSlot slot;
  final ImageProvider image;
  final Offset? centre;
  final double? width;
}

/// A member's mark: their colour with their initial on it. The initial is
/// always drawn, so colour is never the only signal (`FE-13`); a ring marks
/// the member the screen is about.
///
/// Layers paint outside the widget's box (a `top` up to [topOverhang] of
/// [size] above it, a `badge` [badgeOverhang] past its corner) so a row lays
/// out exactly as it does for the initial.
class NestAvatar extends StatelessWidget {
  const NestAvatar({
    required this.name,
    required this.color,
    this.size = NestSize.avatarMedium,
    this.isHighlighted = false,
    this.picture,
    this.layers = const [],
    super.key,
  });

  final String name;
  final MemberColor color;
  final double size;
  final bool isHighlighted;
  final ImageProvider? picture;
  final List<NestAvatarLayer> layers;

  static const topOverhang = 0.26;
  static const badgeOverhang = 0.06;

  static const _ring = 1.16;
  static const _face = 0.52;
  static const _faceCentre = 0.42;
  static const _top = 0.5;
  static const _topSink = 0.24;
  static const _badge = 0.42;

  static Rect layerBox(NestAvatarLayer layer, double size) {
    final (anchor, share) = (layer.centre, layer.width);
    if (anchor != null && share != null) {
      return Rect.fromCenter(
        center: anchor * size,
        width: size * share,
        height: size * share,
      );
    }
    final centre = size / 2;
    return switch (layer.slot) {
      NestAvatarSlot.ring => Rect.fromCenter(
        center: Offset(centre, centre),
        width: size * _ring,
        height: size * _ring,
      ),
      NestAvatarSlot.face => Rect.fromCenter(
        center: Offset(centre, size * _faceCentre),
        width: size * _face,
        height: size * _face,
      ),
      NestAvatarSlot.top => Rect.fromLTWH(
        centre - size * _top / 2,
        -size * (_top - _topSink),
        size * _top,
        size * _top,
      ),
      NestAvatarSlot.badge => Rect.fromLTWH(
        size * (1 + badgeOverhang - _badge),
        size * (1 + badgeOverhang - _badge),
        size * _badge,
        size * _badge,
      ),
    };
  }

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final swatch = nest.members.of(color);
    if (picture == null && layers.isEmpty) {
      return Semantics(
        label: name,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: swatch.fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: isHighlighted
                  ? nest.colors.secondary
                  : nest.colors.surface,
              width: NestStroke.focus,
            ),
          ),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: _Initial(initial: _initial, size: size, swatch: swatch),
            ),
          ),
        ),
      );
    }
    final ground = picture == null ? swatch : NestMemberPalette.light.of(color);
    final initial = Center(
      child: _Initial(initial: _initial, size: size, swatch: ground),
    );
    final pixels = MediaQuery.devicePixelRatioOf(context);
    final ordered = [
      for (final slot in NestAvatarSlot.values)
        ...layers.where((layer) => layer.slot == slot),
    ];
    final rim = Border.all(
      color: isHighlighted ? nest.colors.secondary : nest.colors.surface,
      width: NestStroke.focus,
    );
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ground.fill,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: switch (picture) {
                    final picture? => Image(
                      image: ResizeImage.resizeIfNeeded(
                        (size * pixels).ceil(),
                        null,
                        picture,
                      ),
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => initial,
                    ),
                    null => initial,
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: rim,
                  ),
                ),
              ),
            ),
            for (final layer in ordered)
              _LayerAt(layer: layer, size: size, pixels: pixels),
          ],
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({
    required this.initial,
    required this.size,
    required this.swatch,
  });

  final String initial;
  final double size;
  final MemberSwatch swatch;

  @override
  Widget build(BuildContext context) => Text(
    initial,
    style: NestTheme.of(context).text.bodyStrong
        .copyWith(color: swatch.onFill, fontSize: size * 0.42, height: 1),
  );
}

class _LayerAt extends StatelessWidget {
  const _LayerAt({
    required this.layer,
    required this.size,
    required this.pixels,
  });

  final NestAvatarLayer layer;
  final double size;
  final double pixels;

  @override
  Widget build(BuildContext context) {
    final box = NestAvatar.layerBox(layer, size);
    return Positioned.fromRect(
      rect: box,
      child: Image(
        image: ResizeImage.resizeIfNeeded(
          (box.width * pixels).ceil(),
          null,
          layer.image,
        ),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
