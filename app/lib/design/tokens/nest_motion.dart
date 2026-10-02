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
    required this._revolution,
    required this.isReduced,
  });

  static const _full = NestMotion._(
    quick: Duration(milliseconds: 120),
    standard: Duration(milliseconds: 220),
    slow: Duration(milliseconds: 360),
    stagger: Duration(milliseconds: 70),
    tick: Duration(milliseconds: 45),
    revolution: Duration(seconds: 60),
    isReduced: false,
  );

  static const _reduced = NestMotion._(
    quick: Duration.zero,
    standard: Duration.zero,
    slow: Duration.zero,
    stagger: Duration.zero,
    tick: Duration.zero,
    revolution: Duration.zero,
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

  /// One full turn of the slowest ring of the one thing in the app that keeps
  /// moving: the welcome's orbit (design-system ADR-0006). Faster rings make
  /// a whole number of turns in the same time. Zero means it does not turn —
  /// under reduce-motion, and in the widget suite (see [debugHoldStill]).
  Duration get revolution => debugHoldStill ? Duration.zero : _revolution;
  final Duration _revolution;

  final bool isReduced;

  /// Stops everything that would otherwise move for ever, so `pumpAndSettle`
  /// can settle on a screen that has an orbit on it. Set once for the whole
  /// suite by `test/flutter_test_config.dart`; a test of the turning itself
  /// clears it. Never set in the app.
  static bool debugHoldStill = false;

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standardCurve = Curves.easeInOutCubic;

  /// Something landing with a little overshoot — a job ticked off on a kid's
  /// screen. Only for a moment worth celebrating, and gated like every other
  /// duration.
  static const Curve celebrate = Curves.easeOutBack;

  static NestMotion of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? _reduced : _full;
}
