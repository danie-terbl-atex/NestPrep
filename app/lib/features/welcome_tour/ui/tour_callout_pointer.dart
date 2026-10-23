import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';

/// The small notch on the callout's edge that points at the spotlighted
/// component (welcome-tour ADR-0002). Decoration: the words say what it
/// points at.
class TourCalloutPointer extends StatelessWidget {
  const TourCalloutPointer({required this.pointsUp, super.key});

  /// Up when the callout sits below the component.
  final bool pointsUp;

  static const size = NestSpace.md;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(size * 2, size),
    painter: _PointerPainter(
      color: NestTheme.of(context).colors.surface,
      pointsUp: pointsUp,
    ),
  );
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.color, required this.pointsUp});

  final Color color;
  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final tipY = pointsUp ? 0.0 : size.height;
    final baseY = pointsUp ? size.height : 0.0;
    canvas.drawPath(
      Path()
        ..moveTo(0, baseY)
        ..lineTo(size.width / 2, tipY)
        ..lineTo(size.width, baseY)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.color != color || old.pointsUp != pointsUp;
}
