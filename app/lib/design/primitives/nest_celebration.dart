import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_tag.dart';

class NestCelebration extends StatefulWidget {
  const NestCelebration({
    required this.title,
    required this.onDone,
    this.message,
    this.note,
    this.picture,
    super.key,
  });

  final String title;
  final String? message;
  final String? note;

  /// Shown in place of the star — a chore's own picture (todos ADR-0005).
  final Widget? picture;
  final VoidCallback onDone;

  static const confettiKey = ValueKey('nest-celebration-confetti');
  static const pieceCount = 80;

  static final _showing = Expando<OverlayEntry>();

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    String? note,
    Widget? picture,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _showing[overlay]?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => NestCelebration(
        title: title,
        message: message,
        note: note,
        picture: picture,
        onDone: () {
          if (_showing[overlay] == entry) _showing[overlay] = null;
          entry.remove();
        },
      ),
    );
    _showing[overlay] = entry;
    overlay.insert(entry);
    SemanticsService.sendAnnouncement(
      View.of(context),
      [title, ?message, ?note].join('. '),
      Directionality.of(context),
    );
  }

  @override
  State<NestCelebration> createState() => _NestCelebrationState();
}

class _NestCelebrationState extends State<NestCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  final _confetti = _Confetti(math.Random());
  Animation<double> _cardScale = kAlwaysCompleteAnimation;
  Animation<double> _fade = kAlwaysCompleteAnimation;
  bool _isReduced = false;
  bool _hasStarted = false;

  static const _scrim = 0.72;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    final motion = NestMotion.of(context);
    _isReduced = motion.isReduced;
    if (!_isReduced) {
      _cardScale = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.2, curve: NestMotion.celebrate),
      );
      _fade = ReverseAnimation(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.85, 1, curve: NestMotion.exit),
        ),
      );
    }
    _controller
      ..duration = motion.celebration
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: NestTheme.of(context).colors.canvas
                  .withValues(alpha: _scrim),
            ),
            if (!_isReduced)
              RepaintBoundary(
                child: CustomPaint(
                  key: NestCelebration.confettiKey,
                  painter: _ConfettiPainter(
                    confetti: _confetti,
                    progress: _controller,
                    seconds:
                        (_controller.duration ?? Duration.zero).inMilliseconds /
                        1000,
                  ),
                ),
              ),
            Center(
              child: ScaleTransition(
                scale: _cardScale,
                child: _Card(
                  title: widget.title,
                  message: widget.message,
                  note: widget.note,
                  picture: widget.picture,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, this.message, this.note, this.picture});

  final String title;
  final String? message;
  final String? note;
  final Widget? picture;

  static const _maxWidth = 320.0;
  static const _starDisc = 72.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NestRadius.xxl),
      side: BorderSide(color: c.outline),
    );
    return Padding(
      padding: const EdgeInsets.all(NestSpace.gutter),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            shadows: nest.shadows.floating,
          ),
          child: Material(
            color: c.surface,
            shape: shape,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpace.xxl,
                NestSpace.xxl,
                NestSpace.xxl,
                NestSpace.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?picture,
                  if (picture == null)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: NestColors.butter,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: _starDisc,
                        child: Icon(
                          LucideIcons.star,
                          size: NestSize.iconTile * 0.7,
                          color: NestColors.inkBrand,
                        ),
                      ),
                    ),
                  const SizedBox(height: NestSpace.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: nest.text.headline.copyWith(color: c.ink),
                  ),
                  if (message case final message?) ...[
                    const SizedBox(height: NestSpace.xs),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: nest.text.body.copyWith(color: c.inkSecondary),
                    ),
                  ],
                  if (note case final note?) ...[
                    const SizedBox(height: NestSpace.md),
                    NestTag(
                      label: note,
                      tone: NestTagTone.warning,
                      icon: LucideIcons.star,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Confetti {
  _Confetti(math.Random random) {
    for (var i = 0; i < count; i++) {
      final lane = i % 5;
      if (lane < 2) {
        originX[i] = 0.15 + random.nextDouble() * 0.7;
        originY[i] = 1.05;
        velocityX[i] = (random.nextDouble() - 0.5) * 0.6;
        velocityY[i] = -(1.25 + random.nextDouble() * 0.55);
      } else {
        final fromLeft = lane.isEven;
        originX[i] = fromLeft ? -0.04 : 1.04;
        originY[i] = 0.55 + random.nextDouble() * 0.35;
        velocityX[i] = (fromLeft ? 1 : -1) * (0.35 + random.nextDouble() * 0.5);
        velocityY[i] = -(0.9 + random.nextDouble() * 0.6);
      }
      delay[i] = random.nextDouble() * 0.18;
      angle[i] = random.nextDouble() * math.pi * 2;
      spin[i] = (random.nextDouble() - 0.5) * 14;
      wobble[i] = random.nextDouble() * math.pi * 2;
      tumble[i] = 4 + random.nextDouble() * 8;
      isDot[i] = random.nextDouble() < 0.3 ? 1 : 0;
      paint[i] = random.nextInt(paints.length);
      final side = 9 + random.nextDouble() * 9;
      size[i] = side;
      rects.add(
        Rect.fromCenter(center: Offset.zero, width: side, height: side * 0.5),
      );
    }
  }

  static const count = NestCelebration.pieceCount;
  static const gravity = 1.7;
  static const sway = 14.0;

  final originX = Float32List(count);
  final originY = Float32List(count);
  final velocityX = Float32List(count);
  final velocityY = Float32List(count);
  final delay = Float32List(count);
  final angle = Float32List(count);
  final spin = Float32List(count);
  final wobble = Float32List(count);
  final tumble = Float32List(count);
  final size = Float32List(count);
  final isDot = Uint8List(count);
  final paint = Uint8List(count);
  final rects = <Rect>[];

  final paints = [
    for (final color in const [
      NestColors.guava,
      NestColors.butter,
      NestColors.lilac,
      NestColors.basil,
      NestColors.blush,
      NestColors.oat,
    ])
      Paint()..color = color,
  ];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.confetti,
    required this.progress,
    required this.seconds,
  }) : super(repaint: progress);

  final _Confetti confetti;
  final Animation<double> progress;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = progress.value * seconds;
    final height = size.height;
    final c = confetti;
    for (var i = 0; i < _Confetti.count; i++) {
      final t = elapsed - c.delay[i];
      if (t <= 0) continue;
      final x =
          c.originX[i] * size.width +
          c.velocityX[i] * t * height +
          math.sin(c.wobble[i] + t * 5) * _Confetti.sway;
      final y =
          (c.originY[i] +
              c.velocityY[i] * t +
              0.5 * _Confetti.gravity * t * t) *
          height;
      if (y > height + c.size[i] * 2) continue;
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(c.angle[i] + c.spin[i] * t);
      final ink = c.paints[c.paint[i]];
      if (c.isDot[i] == 1) {
        canvas.drawCircle(Offset.zero, c.size[i] * 0.35, ink);
      } else {
        canvas
          ..scale(1, math.cos(c.tumble[i] * t))
          ..drawRect(c.rects[i], ink);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.confetti != confetti || oldDelegate.seconds != seconds;
}
