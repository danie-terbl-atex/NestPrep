import 'package:flutter/widgets.dart';

/// Durations and curves, behind the one reduce-motion gate (`FE-15`). Ask
/// `NestMotion.of(context)`: when the platform asks for reduced motion every
/// duration is zero, so a transition becomes a cut without any widget checking.
@immutable
class NestMotion {
  const NestMotion._({
    required this.quick,
    required this.standard,
    required this.slow,
    required this.stagger,
    required this.tick,
    required this.isReduced,
  });

  static const _full = NestMotion._(
    quick: Duration(milliseconds: 120),
    standard: Duration(milliseconds: 220),
    slow: Duration(milliseconds: 360),
    stagger: Duration(milliseconds: 70),
    tick: Duration(milliseconds: 45),
    isReduced: false,
  );

  static const _reduced = NestMotion._(
    quick: Duration.zero,
    standard: Duration.zero,
    slow: Duration.zero,
    stagger: Duration.zero,
    tick: Duration.zero,
    isReduced: true,
  );

  /// A hover, press or colour change.
  final Duration quick;

  /// A state change on screen: a row expanding, a banner appearing.
  final Duration standard;

  /// A sheet or a page.
  final Duration slow;

  /// The gap between one item of an entrance and the next, so a group arrives
  /// in the order it reads rather than all at once.
  final Duration stagger;

  /// One character of typed text.
  final Duration tick;

  final bool isReduced;

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standardCurve = Curves.easeInOutCubic;

  static NestMotion of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? _reduced : _full;
}
