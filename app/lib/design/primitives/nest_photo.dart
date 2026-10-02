import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_button.dart';
import 'nest_pressable.dart';

/// A photo, or the drawing that stands in for one, clipped to the brand's
/// round corner (design-system ADR-0008, ADR-0010). With a [heroTag] it flies
/// with its card into [NestPhotoRoute]. [drift] plays the hero entrance once.
/// [zoomed] settles it at the detail zoom. Both are dropped under reduced
/// motion.
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

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final motion = NestMotion.of(context);
    final target = motion.isReduced
        ? 1.0
        : zoomed
        ? NestMotion.photoZoom
        : drift
        ? NestMotion.driftScale
        : 1.0;
    final duration = zoomed ? motion.photo : motion.drift;
    Widget photo = TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: target),
      duration: duration,
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
      flightShuttleBuilder: (_, animation, _, _, toContext) => photo,
      child: Material(type: MaterialType.transparency, child: photo),
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
class NestPhotoRoute<T> extends PageRouteBuilder<T> {
  NestPhotoRoute({
    required WidgetBuilder builder,
    required NestMotion motion,
    super.settings,
  }) : super(
         opaque: true,
         transitionDuration: motion.photo,
         reverseTransitionDuration: motion.slow,
         pageBuilder: (context, _, _) => builder(context),
         transitionsBuilder: (context, animation, _, child) => FadeTransition(
           opacity: CurvedAnimation(
             parent: animation,
             curve: const Interval(0.25, 1, curve: Curves.easeOut),
           ),
           child: child,
         ),
       );
}
