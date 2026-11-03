import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_button.dart';
import 'nest_pressable.dart';

/// A photo, or the drawing that stands in for one, clipped to the brand's
/// round corner (design-system ADR-0008, ADR-0010). With a [heroTag] it flies
/// with its card into [NestPhotoRoute], its corners and zoom turning into the
/// other frame's on the way. [drift] plays the hero entrance once. [zoomed]
/// settles it at the detail zoom — in flight, when a hero carries it there.
/// Both are dropped under reduced motion.
class NestPhotoFrame extends StatelessWidget {
  const NestPhotoFrame({
    required this.child,
    this.heroTag,
    this.radius = NestRadius.xxl,
    this.drift = false,
    this.zoomed = false,
    this.semanticsLabel,
    super.key,
  });

  final Widget child;
  final Object? heroTag;
  final double radius;
  final bool drift;
  final bool zoomed;
  final String? semanticsLabel;

  /// The scale this frame comes to rest at.
  double _restingScale(NestMotion motion) => motion.isReduced
      ? 1.0
      : zoomed
      ? NestMotion.photoZoom
      : drift
      ? NestMotion.driftScale
      : 1.0;

  /// The scale this frame first shows: a zoom a hero has already carried in
  /// flight is not played again on landing.
  double _arrivingScale(NestMotion motion) =>
      zoomed && heroTag != null ? _restingScale(motion) : 1.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final motion = NestMotion.of(context);
    Widget photo = TweenAnimationBuilder<double>(
      tween: Tween(begin: _arrivingScale(motion), end: _restingScale(motion)),
      duration: zoomed ? motion.photo : motion.drift,
      curve: zoomed ? NestMotion.emphasized : Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: SizedBox.expand(child: child),
    );
    photo = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(color: nest.colors.surfaceTint, child: photo),
    );
    final label = semanticsLabel;
    photo = label == null
        ? ExcludeSemantics(child: photo)
        : Semantics(label: label, image: true, child: photo);
    final tag = heroTag;
    if (tag == null) return photo;
    return Hero(
      tag: tag,
      createRectTween: _NestPhotoRectTween.new,
      flightShuttleBuilder: _flight,
      child: Material(type: MaterialType.transparency, child: photo),
    );
  }

  static Widget _flight(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) => _NestPhotoFlight(
    animation: animation,
    from: fromHeroContext.findAncestorWidgetOfExactType<NestPhotoFrame>()!,
    to: toHeroContext.findAncestorWidgetOfExactType<NestPhotoFrame>()!,
  );
}

class _NestPhotoRectTween extends RectTween {
  _NestPhotoRectTween(Rect? begin, Rect? end) : super(begin: begin, end: end);

  @override
  Rect? lerp(double t) => super.lerp(NestMotion.emphasized.transform(t));
}

/// The photo between its two frames: the landing frame's picture, its
/// corners and zoom moving from the frame it left to the one it lands in on
/// the same curve as its bounds, so neither end jumps.
class _NestPhotoFlight extends StatelessWidget {
  const _NestPhotoFlight({
    required this.animation,
    required this.from,
    required this.to,
  });

  final Animation<double> animation;
  final NestPhotoFrame from;
  final NestPhotoFrame to;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final motion = NestMotion.of(context);
    final fromScale = from._restingScale(motion);
    final toScale = to._arrivingScale(motion);
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        child: SizedBox.expand(child: to.child),
        builder: (context, child) {
          final t = NestMotion.emphasized.transform(animation.value);
          return ClipRRect(
            borderRadius: BorderRadius.circular(
              lerpDouble(from.radius, to.radius, t)!,
            ),
            child: ColoredBox(
              color: nest.colors.surfaceTint,
              child: Transform.scale(
                scale: lerpDouble(fromScale, toScale, t)!,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The tappable photo card: the photo with an Oat pill over its corner
/// ("View lunch"), settling under the finger. A tap is the caller's to route,
/// usually into a [NestPhotoRoute] with the same [heroTag].
class NestPhotoCard extends StatelessWidget {
  const NestPhotoCard({
    required this.photo,
    required this.onTap,
    this.actionLabel,
    this.actionIcon,
    this.heroTag,
    this.aspectRatio = 4 / 3,
    this.drift = false,
    this.semanticsLabel,
    super.key,
  });

  final Widget photo;
  final VoidCallback onTap;
  final String? actionLabel;
  final IconData? actionIcon;
  final Object? heroTag;
  final double aspectRatio;
  final bool drift;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      onTap: onTap,
      child: NestPressable(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NestPhotoFrame(heroTag: heroTag, drift: drift, child: photo),
                if (label != null)
                  Positioned(
                    right: NestSpace.md,
                    bottom: NestSpace.md,
                    child: IgnorePointer(
                      child: NestButton(
                        label: label,
                        icon: actionIcon,
                        onPressed: onTap,
                        variant: NestButtonVariant.onPhoto,
                        size: NestButtonSize.small,
                        isExpanded: false,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a photo's detail with the photo and its card expanding together over
/// 420–550 ms. Under reduced motion the page simply appears.
class NestPhotoRoute<T> extends _NestPhotoTransition<T> {
  NestPhotoRoute({
    required this.builder,
    required super.motion,
    super.settings,
  });

  final WidgetBuilder builder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);
}

/// A router's page that opens the way [NestPhotoRoute] does, for a route
/// table whose page is opened from its photo.
class NestPhotoPage<T> extends Page<T> {
  const NestPhotoPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) =>
      _NestPhotoPageRoute<T>(page: this, motion: NestMotion.of(context));
}

class _NestPhotoPageRoute<T> extends _NestPhotoTransition<T> {
  _NestPhotoPageRoute({required NestPhotoPage<T> page, required super.motion})
    : super(settings: page);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => (settings as NestPhotoPage<T>).child;
}

/// The page fading in behind its photo, which flies on its own.
abstract class _NestPhotoTransition<T> extends PageRoute<T> {
  _NestPhotoTransition({required NestMotion motion, super.settings})
    : transitionDuration = motion.photo,
      reverseTransitionDuration = motion.slow;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: const Interval(0.25, 1, curve: Curves.easeOut),
    ),
    child: child,
  );
}
