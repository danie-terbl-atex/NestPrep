import 'package:flutter/widgets.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_spacing.dart';

/// The arch/nest in its Guava tile (design-system ADR-0008), drawn from
/// `nestprep-mark.svg` so it is sharp at any size. The same colours in both
/// themes: it is the mark, not a themed surface.
///
/// Decoration unless given a [semanticsLabel].
class NestBrandMark extends StatelessWidget {
  const NestBrandMark({
    this.size = NestSize.brandMarkMedium,
    this.semanticsLabel,
    super.key,
  });

  final double size;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticsLabel;
    final mark = CustomPaint(
      size: Size.square(size),
      painter: const NestMarkPainter(),
    );
    if (label == null) return ExcludeSemantics(child: mark);
    return Semantics(label: label, image: true, child: mark);
  }
}

class NestMarkPainter extends CustomPainter {
  const NestMarkPainter({
    this.tile = NestColors.guava,
    this.stroke = NestColors.inkBrand,
  });

  final Color tile;
  final Color stroke;

  static const _box = 96.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _box, size.height / _box);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, _box, _box),
        const Radius.circular(28),
      ),
      Paint()..color = tile,
    );
    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arch = Path()
      ..moveTo(25, 54)
      ..lineTo(25, 44)
      ..cubicTo(25, 31, 34, 22, 48, 22)
      ..cubicTo(62, 22, 71, 31, 71, 44)
      ..lineTo(71, 54);
    canvas.drawPath(arch, line..strokeWidth = 8);
    final nest = Path()
      ..moveTo(23, 63)
      ..cubicTo(29, 72, 37, 76, 48, 76)
      ..cubicTo(59, 76, 67, 72, 73, 63)
      ..moveTo(34, 55)
      ..cubicTo(38, 60, 42, 62, 48, 62)
      ..cubicTo(54, 62, 58, 60, 62, 55);
    canvas.drawPath(nest, line..strokeWidth = 7);
  }

  @override
  bool shouldRepaint(NestMarkPainter oldDelegate) =>
      tile != oldDelegate.tile || stroke != oldDelegate.stroke;
}
