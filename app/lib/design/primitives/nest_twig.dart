import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../tokens/nest_imagery.dart';
import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';

/// What Twig does once before he rests (design-system ADR-0026).
enum NestTwigAction {
  /// Pops into place and settles.
  arrive,

  /// A hop with a squash on take-off and landing.
  hop,

  /// Two nods that die away.
  nod,

  /// A wave: the wing itself on a rigged pose, the whole bird otherwise.
  wave,

  /// Two hops and a wiggle.
  cheer,
}

/// Twig, NestPrep's mascot (design-system ADR-0026), in one of its
/// [NestTwigPose]s.
///
/// Twig is the bird alone, straight on the canvas in both themes: his fills
/// carry him on the dark canvas where his brown outline does not. The picture
/// holds its box before it is decoded, so nothing around it moves when it
/// arrives.
///
/// Given an [action] he plays it once when he first shows and again whenever
/// [actionKey] changes, then rests on the still pose: he never loops, a
/// resting Twig schedules no frames, and under reduce-motion he is the still
/// pose alone. While he acts, one painter draws the art, turning
/// a rigged pose's wing, crest and tail about their own pivots.
///
/// Decoration unless given a [semanticsLabel] — label it only where nothing
/// beside it already says what he stands for.
class NestTwig extends StatefulWidget {
  const NestTwig({
    required this.pose,
    this.size = NestSize.twigMedium,
    this.semanticsLabel,
    this.action,
    this.actionKey,
    super.key,
  });

  final NestTwigPose pose;

  final double size;
  final String? semanticsLabel;
  final NestTwigAction? action;

  /// Plays [action] again each time it changes — a screen reacting to
  /// something the person did, never a timer.
  final Object? actionKey;

  @override
  State<NestTwig> createState() => _NestTwigState();
}

class _NestTwigState extends State<NestTwig>
    with SingleTickerProviderStateMixin {
  AnimationController? _clock;
  _TwigArt? _art;
  bool _hasStarted = false;
  bool _isWaiting = false;

  AnimationController get _controller =>
      _clock ??= AnimationController(vsync: this)..addStatusListener(_settle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    _play();
  }

  @override
  void didUpdateWidget(NestTwig oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose) {
      _art?.dispose();
      _art = null;
    }
    if (oldWidget.actionKey != widget.actionKey ||
        oldWidget.action != widget.action) {
      _play();
    }
  }

  void _play() {
    final action = widget.action;
    if (action == null) return;
    final duration = _durationOf(action, NestMotion.of(context));
    if (duration == Duration.zero) return;
    final art = _art ??= _TwigArt(widget.pose, context);
    if (!art.isReady) {
      _isWaiting = true;
      art.whenReady(() {
        if (!mounted || !_isWaiting) return;
        _isWaiting = false;
        _start(duration);
      });
      return;
    }
    _start(duration);
  }

  void _start(Duration duration) {
    _controller
      ..duration = duration
      ..forward(from: 0);
    setState(() {});
  }

  void _settle(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) setState(() {});
  }

  static Duration _durationOf(NestTwigAction action, NestMotion motion) =>
      switch (action) {
        NestTwigAction.arrive || NestTwigAction.hop => motion.twigHop,
        NestTwigAction.nod => motion.twigNod,
        NestTwigAction.wave => motion.twigWave,
        NestTwigAction.cheer => motion.twigCheer,
      };

  @override
  void dispose() {
    _isWaiting = false;
    _clock?.dispose();
    _art?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final clock = _clock;
    final art = _art;
    final action = widget.action;
    final isActing =
        action != null &&
        clock != null &&
        clock.isAnimating &&
        TickerMode.valuesOf(context).enabled &&
        art != null &&
        art.isReady;
    final Widget bird;
    if (isActing) {
      bird = RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _TwigPainter(clock: clock, action: action, art: art),
        ),
      );
    } else if (_isWaiting && action == NestTwigAction.arrive) {
      bird = SizedBox.square(dimension: size);
    } else {
      bird = Image.asset(
        widget.pose.asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      );
    }
    final label = widget.semanticsLabel;
    if (label == null) return ExcludeSemantics(child: bird);
    return Semantics(label: label, image: true, child: bird);
  }
}

/// The decoded pictures a pose acts with: the pose itself, and its rig's
/// layers when it has one. Held only while that Twig is on screen.
class _TwigArt {
  _TwigArt(this.pose, BuildContext context) {
    final configuration = createLocalImageConfiguration(context);
    final assets = [pose.asset, for (final layer in pose.rig) layer.asset];
    _images = List.filled(assets.length, null);
    for (final (index, asset) in assets.indexed) {
      final stream = AssetImage(asset).resolve(configuration);
      final listener = ImageStreamListener(
        (info, _) {
          _images[index]?.dispose();
          _images[index] = info;
          if (isReady) _announce();
        },
        // A layer that fails to decode leaves the art unready, so the pose
        // stays still: nothing to show the person.
        onError: (_, _) {},
      );
      stream.addListener(listener);
      _streams.add((stream, listener));
    }
  }

  final NestTwigPose pose;
  late final List<ImageInfo?> _images;
  final _streams = <(ImageStream, ImageStreamListener)>[];
  final _waiting = <VoidCallback>[];

  bool get isReady => _images.every((image) => image != null);

  ui.Image get still => _images.first!.image;

  /// The rig's layers in draw order, empty for a pose without one.
  Iterable<(NestTwigLayer, ui.Image)> get layers sync* {
    for (final (index, layer) in pose.rig.indexed) {
      yield (layer, _images[index + 1]!.image);
    }
  }

  bool get isRigged => pose.rig.isNotEmpty;

  void whenReady(VoidCallback callback) {
    if (isReady) return callback();
    _waiting.add(callback);
  }

  void _announce() {
    final waiting = [..._waiting];
    _waiting.clear();
    for (final callback in waiting) {
      callback();
    }
  }

  void dispose() {
    for (final (stream, listener) in _streams) {
      stream.removeListener(listener);
    }
    for (final image in _images) {
      image?.dispose();
    }
    _waiting.clear();
  }
}

/// Where the whole bird is at one moment of an action, and how far each
/// rigged part has turned. One is kept per painter and refilled each frame.
class _Stance {
  double lift = 0;
  double stretchX = 1;
  double stretchY = 1;
  double turn = 0;
  double opacity = 1;
  double wing = 0;
  double crest = 0;
  double tail = 0;
  bool eyesClosed = false;

  void rest() {
    lift = 0;
    stretchX = 1;
    stretchY = 1;
    turn = 0;
    opacity = 1;
    wing = 0;
    crest = 0;
    tail = 0;
    eyesClosed = false;
  }

  void hop(double t, {double height = 0.16}) {
    if (t < 0.15) {
      final squash = math.sin(math.pi * t / 0.15);
      stretchY = 1 - 0.07 * squash;
      stretchX = 1 + 0.05 * squash;
    } else if (t < 0.7) {
      final air = math.sin(math.pi * (t - 0.15) / 0.55);
      lift = height * air;
      stretchY = 1 + 0.04 * air;
      stretchX = 1 - 0.03 * air;
    } else {
      final land = math.sin(math.pi * (t - 0.7) / 0.3);
      stretchY = 1 - 0.06 * land;
      stretchX = 1 + 0.045 * land;
    }
  }

  void act(NestTwigAction action, double t, {required bool isRigged}) {
    rest();
    final envelope = math.sin(math.pi * t);
    switch (action) {
      case NestTwigAction.arrive:
        final grow = NestMotion.celebrate.transform(math.min(1, t / 0.6));
        stretchX = stretchY = 0.5 + 0.5 * grow;
        opacity = math.min(1, t / 0.25);
        if (t > 0.6) {
          final land = math.sin(math.pi * (t - 0.6) / 0.4);
          stretchY *= 1 - 0.04 * land;
          stretchX *= 1 + 0.03 * land;
        }
      case NestTwigAction.hop:
        hop(t);
      case NestTwigAction.nod:
        turn = -0.1 * math.sin(4 * math.pi * t) * (1 - t);
        stretchY = 1 - 0.02 * math.sin(4 * math.pi * t).abs() * (1 - t);
      case NestTwigAction.wave:
        final beat = 6 * math.pi * t;
        if (isRigged) {
          turn = 0.03 * math.sin(3 * math.pi * t) * envelope;
          wing = 0.32 * math.sin(beat) * envelope;
          crest = 0.12 * math.sin(beat - 0.9) * envelope;
          tail = 0.1 * math.sin(beat - 1.7) * envelope;
          eyesClosed = t > 0.42 && t < 0.5;
        } else {
          turn = 0.08 * math.sin(beat) * envelope;
        }
      case NestTwigAction.cheer:
        if (t < 0.5) {
          hop(t / 0.5);
        } else {
          hop((t - 0.5) / 0.5, height: 0.11);
        }
        turn = 0.05 * math.sin(4 * math.pi * t) * (1 - t);
        if (isRigged) {
          crest = 0.1 * math.sin(4 * math.pi * t - 0.8) * (1 - t);
          tail = 0.08 * math.sin(4 * math.pi * t - 1.4) * (1 - t);
          eyesClosed = t > 0.55 && t < 0.63;
        }
    }
  }

  double turnOf(NestTwigPart part) => switch (part) {
    NestTwigPart.wing => wing,
    NestTwigPart.crest => crest,
    NestTwigPart.tail => tail,
    NestTwigPart.body || NestTwigPart.eyesClosed => 0,
  };
}

/// Draws the art for one frame of an action, about the bird's foot so a hop
/// squashes onto the ground. Nothing is allocated per frame but the canvas's
/// own work: the stance, paint and rectangles are kept.
class _TwigPainter extends CustomPainter {
  _TwigPainter({required this.clock, required this.action, required this.art})
    : super(repaint: clock);

  final AnimationController clock;
  final NestTwigAction action;
  final _TwigArt art;

  final _stance = _Stance();
  final _artPaint = Paint()..filterQuality = FilterQuality.medium;
  int? _alpha;
  Size? _laidOutFor;
  late Rect _artRect;
  late Rect _stillSource;
  late Rect _layerSource;

  void _layOut(Size size) {
    if (_laidOutFor == size) return;
    _laidOutFor = size;
    _artRect = Offset.zero & size;
    final still = art.still;
    _stillSource = Rect.fromLTWH(
      0,
      0,
      still.width.toDouble(),
      still.height.toDouble(),
    );
    final layerSide = NestTwigRig.rasterSize.toDouble();
    _layerSource = Rect.fromLTWH(0, 0, layerSide, layerSide);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _layOut(size);
    final stance = _stance..act(action, clock.value, isRigged: art.isRigged);
    final alpha = (stance.opacity * 255).round();
    if (alpha != _alpha) {
      _alpha = alpha;
      _artPaint.color = _artPaint.color.withAlpha(alpha);
    }

    canvas
      ..save()
      ..translate(size.width / 2, size.height * (1 - stance.lift))
      ..rotate(stance.turn)
      ..scale(stance.stretchX, stance.stretchY)
      ..translate(-size.width / 2, -size.height);

    if (!art.isRigged) {
      canvas
        ..drawImageRect(art.still, _stillSource, _artRect, _artPaint)
        ..restore();
      return;
    }
    for (final (layer, image) in art.layers) {
      if (layer.part == NestTwigPart.eyesClosed && !stance.eyesClosed) {
        continue;
      }
      final turn = stance.turnOf(layer.part);
      if (turn == 0) {
        canvas.drawImageRect(image, _layerSource, _artRect, _artPaint);
        continue;
      }
      final pivot = Offset(
        _artRect.left + layer.pivot.dx * _artRect.width,
        _artRect.top + layer.pivot.dy * _artRect.height,
      );
      canvas
        ..save()
        ..translate(pivot.dx, pivot.dy)
        ..rotate(turn)
        ..translate(-pivot.dx, -pivot.dy)
        ..drawImageRect(image, _layerSource, _artRect, _artPaint)
        ..restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TwigPainter oldDelegate) =>
      oldDelegate.action != action || oldDelegate.art != art;
}
