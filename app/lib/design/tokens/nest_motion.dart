import 'package:flutter/widgets.dart';

/// Durations and curves behind the one reduce-motion gate (`FE-15`,
/// design-system ADR-0008). Under reduced motion every duration is zero and
/// [isReduced] tells a widget to drop zoom, movement and stagger.
@immutable
class NestMotion {
  const NestMotion._({
    required this.quick,
    required this.standard,
    required this.slow,
    required this.photo,
    required this.drift,
    required this.stagger,
    required this._revolution,
    required this.isReduced,
  });

  static const _full = NestMotion._(
    quick: Duration(milliseconds: 140),
    standard: Duration(milliseconds: 220),
    slow: Duration(milliseconds: 360),
    photo: Duration(milliseconds: 480),
    drift: Duration(seconds: 4),
    stagger: Duration(milliseconds: 60),
    revolution: Duration(seconds: 60),
    isReduced: false,
  );

  static const _reduced = NestMotion._(
    quick: Duration.zero,
    standard: Duration.zero,
    slow: Duration.zero,
    photo: Duration.zero,
    drift: Duration.zero,
    stagger: Duration.zero,
    revolution: Duration.zero,
    isReduced: true,
  );

  /// Press feedback.
  final Duration quick;

  /// A list changing or a row expanding.
  final Duration standard;

  /// A sheet or a page.
  final Duration slow;

  /// A photo opening with its card.
  final Duration photo;

  /// The once-only entrance drift on a hero photo.
  final Duration drift;
  final Duration stagger;

  /// One full turn of the slowest ring of the welcome's orbit
  /// (design-system ADR-0006). Zero under reduce-motion, and in the widget
  /// suite (see [debugHoldStill]).
  Duration get revolution => debugHoldStill ? Duration.zero : _revolution;
  final Duration _revolution;

  final bool isReduced;

  /// Stops the orbit turning so `pumpAndSettle` can settle. Set for the whole
  /// suite by `test/flutter_test_config.dart`; never set in the app.
  static bool debugHoldStill = false;

  static const double pressScale = 0.98;
  static const double photoZoom = 1.06;
  static const double driftScale = 1.04;

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve celebrate = Curves.easeOutBack;

  static NestMotion of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? _reduced : _full;
}
