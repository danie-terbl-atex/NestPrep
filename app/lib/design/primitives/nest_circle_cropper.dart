import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

class NestCircleCropper extends StatefulWidget {
  const NestCircleCropper({
    required this.image,
    required this.imageSize,
    required this.onArea,
    required this.label,
    this.maxSide = NestSize.cropperMax,
    super.key,
  });

  final ImageProvider image;
  final Size imageSize;
  final ValueChanged<Rect> onArea;
  final String label;
  final double maxSide;

  static const maxZoom = 4.0;

  static Rect areaOf(Matrix4 transform, Size child, double side) {
    final inverse = Matrix4.inverted(transform);
    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(inverse, Offset(side, side));
    return Rect.fromLTRB(
      (topLeft.dx / child.width).clamp(0, 1),
      (topLeft.dy / child.height).clamp(0, 1),
      (bottomRight.dx / child.width).clamp(0, 1),
      (bottomRight.dy / child.height).clamp(0, 1),
    );
  }

  @override
  State<NestCircleCropper> createState() => _NestCircleCropperState();
}

class _NestCircleCropperState extends State<NestCircleCropper> {
  final _transform = TransformationController();
  double? _side;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_report);
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_report)
      ..dispose();
    super.dispose();
  }

  Size _childFor(double side) {
    final image = widget.imageSize;
    final shorter = math.min(image.width, image.height);
    final scale = shorter <= 0 ? 1.0 : side / shorter;
    return Size(image.width * scale, image.height * scale);
  }

  void _centre(double side) {
    final child = _childFor(side);
    _transform
      ..removeListener(_report)
      ..value = Matrix4.translationValues(
        -(child.width - side) / 2,
        -(child.height - side) / 2,
        0,
      )
      ..addListener(_report);
  }

  void _report() {
    final side = _side;
    if (side == null) return;
    widget.onArea(
      NestCircleCropper.areaOf(_transform.value, _childFor(side), side),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, widget.maxSide);
        if (_side != side) {
          _side = side;
          _centre(side);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _report();
          });
        }
        final child = _childFor(side);
        return Center(
          child: Semantics(
            image: true,
            label: widget.label,
            child: SizedBox.square(
              dimension: side,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(NestRadius.xl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: c.surfaceTint),
                    InteractiveViewer(
                      transformationController: _transform,
                      constrained: false,
                      minScale: 1,
                      maxScale: NestCircleCropper.maxZoom,
                      child: SizedBox.fromSize(
                        size: child,
                        child: Image(
                          image: widget.image,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _CircleMask(shade: c.scrim, rim: c.surface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircleMask extends CustomPainter {
  const _CircleMask({required this.shade, required this.rim});

  final Color shade;
  final Color rim;

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(circle),
          Path()..addOval(circle.deflate(NestStroke.focus)),
        ),
        Paint()..color = shade,
      )
      ..drawOval(
        circle.deflate(NestStroke.focus),
        Paint()
          ..color = rim
          ..style = PaintingStyle.stroke
          ..strokeWidth = NestStroke.focus,
      );
  }

  @override
  bool shouldRepaint(_CircleMask oldDelegate) =>
      oldDelegate.shade != shade || oldDelegate.rim != rim;
}
