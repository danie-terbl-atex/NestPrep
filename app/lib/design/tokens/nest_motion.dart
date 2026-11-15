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
    required this.tick,
    required this.celebration,
    required this.sheen,
    required this._revolution,
    required this._wobble,
    required this._swell,
    required this._sway,
    required this.isReduced,
  });

  static const _full = NestMotion._(
    quick: Duration(milliseconds: 140),
    standard: Duration(milliseconds: 220),
    slow: Duration(milliseconds: 360),
    photo: Duration(milliseconds: 480),
    drift: Duration(seconds: 4),
    stagger: Duration(milliseconds: 60),
    tick: Duration(milliseconds: 450),
    celebration: Duration(milliseconds: 2200),
    sheen: Duration(milliseconds: 1400),
    revolution: Duration(seconds: 60),
    wobble: Duration(milliseconds: 1800),
    swell: Duration(milliseconds: 1100),
    sway: Duration(seconds: 5),
    isReduced: false,
  );

  static const _reduced = NestMotion._(
    quick: Duration.zero,
    standard: Duration.zero,
    slow: Duration.zero,
    photo: Duration.zero,
    drift: Duration.zero,
    stagger: Duration.zero,
    tick: Duration.zero,
    celebration: Duration(milliseconds: 1400),
    sheen: Duration.zero,
    revolution: Duration.zero,
    wobble: Duration.zero,
    swell: Duration.zero,
    sway: Duration.zero,
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

  final Duration tick;

  /// Not zero under reduce-motion: the card still has to be read.
  final Duration celebration;

  /// The once-only sheen across Premium's card, its wait included.
  final Duration sheen;

  /// One full turn of the slowest ring of the welcome's orbit
  /// (design-system ADR-0006). Zero under reduce-motion, and in the widget
  /// suite (see [debugHoldStill]).
  Duration get revolution => debugHoldStill ? Duration.zero : _revolution;
  final Duration _revolution;

  /// One rock and rest of an egg that is still hatching. Zero under
  /// reduce-motion and in the widget suite, like [revolution].
  Duration get wobble => debugHoldStill ? Duration.zero : _wobble;
  final Duration _wobble;

  /// How long one point of a sign-in wave takes to roll in from its edge
  /// (design-system ADR-0023). Zero under reduce-motion and in the widget
  /// suite, so the waves are drawn where they settle.
  Duration get swell => debugHoldStill ? Duration.zero : _swell;
  final Duration _swell;

  /// One whole sway of the settled waves, back to where it began. Zero under
  /// reduce-motion and in the widget suite, like [revolution].
  Duration get sway => debugHoldStill ? Duration.zero : _sway;
  final Duration _sway;

  final bool isReduced;

  /// Stops the orbit turning and the waves swaying so `pumpAndSettle` can
  /// settle. Set for the whole suite by `test/flutter_test_config.dart`; never
  /// set in the app.
  static bool debugHoldStill = false;

  static const undoWindow = Duration(seconds: 5);

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
