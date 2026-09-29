import 'package:flutter/material.dart';

import '../model/spot_mark.dart';

/// Draws the circles a parent put round a spot, over the photo, at whatever
/// size the photo is shown (home-care ADR-0001). Each stroke is drawn twice —
/// a wide halo under a narrower line — so it reads on a dark tile and a white
/// wall alike.
class SpotMarksPainter extends CustomPainter {
  const SpotMarksPainter({
    required this.marks,
    required this.line,
    required this.halo,
    this.drawing = const [],
  });

  final List<SpotMark> marks;

  /// The stroke still under somebody's finger, in this box's own pixels.
  final List<Offset> drawing;
  final Color line;
  final Color halo;

  /// How thick a mark is, as a share of the photo's shorter side — so a
  /// circle looks the same on a thumbnail and full screen.
  static const _thickness = 0.018;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.shortestSide * _thickness;
    final haloPaint = _paint(halo, width * 2.2);
    final linePaint = _paint(line, width);
    for (final points in [
      for (final mark in marks) mark.offsetsIn(size),
      if (drawing.isNotEmpty) drawing,
    ]) {
      final path = _pathThrough(points);
      canvas
        ..drawPath(path, haloPaint)
        ..drawPath(path, linePaint);
    }
  }

  static Paint _paint(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static Path _pathThrough(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      // A tap is a dot, not nothing.
      path.lineTo(points.first.dx + 0.1, points.first.dy);
      return path;
    }
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(SpotMarksPainter oldDelegate) =>
      oldDelegate.marks != marks ||
      oldDelegate.drawing != drawing ||
      oldDelegate.line != line ||
      oldDelegate.halo != halo;
}
