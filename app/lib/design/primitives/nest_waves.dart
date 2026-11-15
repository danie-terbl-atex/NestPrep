import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_motion.dart';
import '../tokens/nest_theme.dart';

/// The brand waves of the frame's boot screen (NestPrep-Home ADR-0016), as a
/// backdrop: five flat waves roll in from the top and bottom edges, then sway
/// for as long as they are on screen (design-system ADR-0023). Under
/// reduce-motion they are drawn where they settle and never move.
class NestWaves extends StatefulWidget {
  const NestWaves({super.key});

  @override
  State<NestWaves> createState() => _NestWavesState();
}

class _NestWavesState extends State<NestWaves> with TickerProviderStateMixin {
  /// The waves still mounted, oldest first. A screen that opens over another
  /// with waves (the session gate handing over to sign-in) carries on from
  /// where they are rather than rolling in again.
  static final _mounted = <_NestWavesState>[];

  late final AnimationController _swell = AnimationController(vsync: this);
  late final AnimationController _sway = AnimationController(vsync: this);
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    if (_mounted.lastOrNull case final previous?) {
      _swell.value = previous._swell.value;
      _sway.value = previous._sway.value;
    }
    _mounted.add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = NestMotion.of(context);
    if (!_hasStarted) {
      _hasStarted = true;
      _rollIn(motion.swell);
    }
    _syncSway(motion.sway);
  }

  void _rollIn(Duration swell) {
    if (swell == Duration.zero) {
      _swell.value = 1;
      return;
    }
    _swell.duration = swell * _WaveGeometry.rollInSwells;
    _swell.forward().then((_) {
      if (mounted) _syncSway(NestMotion.of(context).sway);
    });
  }

  /// The sway waits for the roll-in, and stops where it got to if
  /// reduce-motion comes on while the screen is open.
  void _syncSway(Duration sway) {
    if (sway == Duration.zero) {
      _sway.stop();
      return;
    }
    if (!_swell.isCompleted) return;
    if (_sway.isAnimating && _sway.duration == sway) return;
    _sway
      ..duration = sway
      ..repeat();
  }

  @override
  void dispose() {
    _mounted.remove(this);
    _swell.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WavesPainter(
            swell: _swell,
            sway: _sway,
            colors: NestTheme.of(context).colors,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

enum _Edge { top, bottom }

/// One wave as the frame draws it: the edge it hangs from, the side it rolls
/// in from, and its depth at points across the width, in frame pixels.
@immutable
class _Wave {
  const _Wave({
    required this.tone,
    required this.edge,
    required this.fromLeft,
    required this.delay,
    required this.phase,
    required this.points,
  });

  final int tone;
  final _Edge edge;
  final bool fromLeft;

  /// When it starts rolling in, in swells.
  final double delay;

  /// Where in its sway it starts, in sways.
  final double phase;
  final List<(double, double)> points;
}

/// The geometry of `tools/bootbrand/scene.html` in NestPrep-Home, which was
/// drawn at 1080 frame pixels high.
abstract final class _WaveGeometry {
  static const frameHeight = 1080.0;

  /// A frame is landscape and a phone is portrait: on a narrow screen depths
  /// follow the width instead, so the waves hug the corners rather than reach
  /// for the middle.
  static const portraitDepth = 1.6;

  static const sweep = 0.36;
  static const drift = 0.12;
  static const hide = 80.0;
  static const sway = 22.0;

  /// The latest a point finishes, in swells: the last wave's delay, its sweep
  /// across the width, and its own swell.
  static const rollInSwells = 1 + sweep + 0.14;

  static const waves = [
    _Wave(
      tone: 1,
      edge: _Edge.top,
      fromLeft: false,
      delay: 0,
      phase: 0,
      points: [
        (-0.05, 150),
        (0.15, 175),
        (0.38, 105),
        (0.62, 70),
        (0.85, 120),
        (1.05, 175),
      ],
    ),
    _Wave(
      tone: 0,
      edge: _Edge.top,
      fromLeft: true,
      delay: 0.09,
      phase: 0.35,
      points: [
        (-0.05, 330),
        (0.12, 300),
        (0.3, 190),
        (0.45, 70),
        (0.58, -10),
        (0.7, -40),
        (1.05, -40),
      ],
    ),
    _Wave(
      tone: 1,
      edge: _Edge.bottom,
      fromLeft: false,
      delay: 0.045,
      phase: 0.6,
      points: [(-0.05, -40), (0.45, -30), (0.65, 70), (0.85, 190), (1.05, 230)],
    ),
    _Wave(
      tone: 2,
      edge: _Edge.bottom,
      fromLeft: true,
      delay: 0,
      phase: 0.15,
      points: [
        (-0.05, 300),
        (0.12, 290),
        (0.3, 200),
        (0.48, 110),
        (0.62, 60),
        (0.8, -40),
        (1.05, -40),
      ],
    ),
    _Wave(
      tone: 0,
      edge: _Edge.bottom,
      fromLeft: false,
      delay: 0.14,
      phase: 0.8,
      points: [
        (-0.05, -40),
        (0.28, -30),
        (0.45, 50),
        (0.62, 150),
        (0.8, 215),
        (0.92, 200),
        (1.05, 150),
      ],
    ),
  ];

  /// The frame's overshoot as a wave lands.
  static double settle(double x) =>
      1 + 1.4 * math.pow(x - 1, 3) + 0.4 * math.pow(x - 1, 2);
}

class _WavesPainter extends CustomPainter {
  _WavesPainter({required this.swell, required this.sway, required this.colors})
    : super(repaint: Listenable.merge([swell, sway]));

  final Animation<double> swell;
  final Animation<double> sway;
  final NestColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(
      size.height / _WaveGeometry.frameHeight,
      size.width * _WaveGeometry.portraitDepth / _WaveGeometry.frameHeight,
    );
    final elapsed = swell.value * _WaveGeometry.rollInSwells;
    for (final wave in _WaveGeometry.waves) {
      final path = _shape(wave, size, unit, elapsed);
      if (path == null) continue;
      canvas.drawPath(path, Paint()..color = colors.waves[wave.tone]);
    }
  }

  Path? _shape(_Wave wave, Size size, double unit, double elapsed) {
    final top = wave.edge == _Edge.top;
    double edgeY(double depth) => top ? depth : size.height - depth;
    final direction = wave.fromLeft ? -1 : 1;

    final landed = [
      for (final (x, _) in wave.points)
        (elapsed -
                wave.delay -
                _WaveGeometry.sweep * (wave.fromLeft ? x : 1 - x))
            .clamp(0.0, 1.0),
    ];
    if (landed.every((k) => k == 0)) return null;

    final points = [
      for (var i = 0; i < wave.points.length; i++)
        _point(wave, size, unit, edgeY, direction, wave.points[i], landed[i]),
    ];

    final rim = edgeY(-(_WaveGeometry.hide + 20) * unit);
    final path = Path()
      ..moveTo(points.first.dx, rim)
      ..lineTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[math.min(points.length - 1, i + 2)];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path
      ..lineTo(points.last.dx, rim)
      ..close();
  }

  Offset _point(
    _Wave wave,
    Size size,
    double unit,
    double Function(double) edgeY,
    int direction,
    (double, double) point,
    double landed,
  ) {
    final (x, depth) = point;
    final e = _WaveGeometry.settle(landed);
    final swayed =
        depth +
        _WaveGeometry.sway *
            math.sin(
              2 * math.pi * (sway.value + wave.phase) + direction * math.pi * x,
            );
    return Offset(
      size.width * (x + direction * _WaveGeometry.drift * (1 - e)),
      edgeY((-_WaveGeometry.hide + (swayed + _WaveGeometry.hide) * e) * unit),
    );
  }

  @override
  bool shouldRepaint(_WavesPainter old) => old.colors != colors;
}
