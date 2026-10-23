import 'package:flutter/widgets.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A sign-in provider whose mark the app draws.
enum NestProvider { google, apple }

/// Somebody else's sign-in mark, drawn from the provider's published path so
/// it is sharp at any size without an image asset (`FE-18`). Google's "G" keeps
/// its own four colours in both themes, as its brand rules ask; Apple's is a
/// single colour and takes the theme's ink, so it is black on light and white
/// on dark, as Apple's rules ask.
///
/// Always decoration: the button around it carries the words (`FE-13`).
class NestProviderMark extends StatelessWidget {
  const NestProviderMark({
    required this.provider,
    this.size = NestSize.iconMedium,
    super.key,
  });

  final NestProvider provider;
  final double size;

  @override
  Widget build(BuildContext context) {
    final painter = switch (provider) {
      NestProvider.google => const _GoogleMarkPainter(),
      NestProvider.apple => _AppleMarkPainter(NestTheme.of(context).colors.ink),
    };
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: painter),
    );
  }
}

/// Google's "G", from its 48-unit brand path scaled to a unit square.
class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width, size.height);
    final red = Path()
      ..moveTo(0.5, 0.198)
      ..cubicTo(0.574, 0.198, 0.64, 0.223, 0.692, 0.273)
      ..lineTo(0.835, 0.13)
      ..cubicTo(0.748, 0.05, 0.635, 0, 0.5, 0)
      ..cubicTo(0.305, 0, 0.136, 0.112, 0.053, 0.275)
      ..lineTo(0.22, 0.404)
      ..cubicTo(0.259, 0.286, 0.37, 0.198, 0.5, 0.198)
      ..close();
    final blue = Path()
      ..moveTo(0.979, 0.511)
      ..cubicTo(0.979, 0.479, 0.976, 0.447, 0.971, 0.417)
      ..lineTo(0.5, 0.417)
      ..lineTo(0.5, 0.605)
      ..lineTo(0.77, 0.605)
      ..cubicTo(0.757, 0.666, 0.722, 0.719, 0.67, 0.754)
      ..lineTo(0.831, 0.879)
      ..cubicTo(0.925, 0.792, 0.979, 0.663, 0.979, 0.511)
      ..close();
    final yellow = Path()
      ..moveTo(0.219, 0.596)
      ..cubicTo(0.209, 0.565, 0.204, 0.533, 0.204, 0.5)
      ..cubicTo(0.204, 0.467, 0.209, 0.435, 0.219, 0.404)
      ..lineTo(0.053, 0.275)
      ..cubicTo(0.019, 0.343, 0, 0.419, 0, 0.5)
      ..cubicTo(0, 0.581, 0.019, 0.657, 0.053, 0.725)
      ..lineTo(0.219, 0.596)
      ..close();
    final green = Path()
      ..moveTo(0.5, 1)
      ..cubicTo(0.635, 1, 0.749, 0.956, 0.831, 0.879)
      ..lineTo(0.67, 0.754)
      ..cubicTo(0.625, 0.784, 0.567, 0.802, 0.5, 0.802)
      ..cubicTo(0.37, 0.802, 0.259, 0.714, 0.219, 0.595)
      ..lineTo(0.053, 0.724)
      ..cubicTo(0.136, 0.888, 0.305, 1, 0.5, 1)
      ..close();
    canvas
      ..drawPath(red, Paint()..color = NestColors.googleRed)
      ..drawPath(blue, Paint()..color = NestColors.googleBlue)
      ..drawPath(yellow, Paint()..color = NestColors.googleYellow)
      ..drawPath(green, Paint()..color = NestColors.googleGreen);
  }

  @override
  bool shouldRepaint(_GoogleMarkPainter oldDelegate) => false;
}

/// Apple's mark, from its 24-unit path scaled to a unit square.
class _AppleMarkPainter extends CustomPainter {
  const _AppleMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width, size.height);
    final mark = Path()
      ..moveTo(0.506, 0.287)
      ..cubicTo(0.467, 0.287, 0.406, 0.242, 0.341, 0.244)
      ..cubicTo(0.256, 0.245, 0.178, 0.293, 0.135, 0.37)
      ..cubicTo(0.046, 0.523, 0.112, 0.749, 0.198, 0.873)
      ..cubicTo(0.24, 0.934, 0.29, 1.002, 0.356, 1)
      ..cubicTo(0.419, 0.997, 0.443, 0.959, 0.52, 0.959)
      ..cubicTo(0.596, 0.959, 0.618, 1, 0.685, 0.998)
      ..cubicTo(0.753, 0.997, 0.796, 0.937, 0.838, 0.876)
      ..cubicTo(0.886, 0.805, 0.906, 0.737, 0.907, 0.733)
      ..cubicTo(0.906, 0.733, 0.775, 0.682, 0.773, 0.531)
      ..cubicTo(0.772, 0.404, 0.876, 0.344, 0.881, 0.341)
      ..cubicTo(0.822, 0.254, 0.73, 0.244, 0.698, 0.242)
      ..cubicTo(0.615, 0.235, 0.545, 0.287, 0.506, 0.287)
      ..close()
      ..moveTo(0.647, 0.16)
      ..cubicTo(0.682, 0.117, 0.705, 0.058, 0.699, 0)
      ..cubicTo(0.649, 0.002, 0.588, 0.034, 0.552, 0.076)
      ..cubicTo(0.519, 0.113, 0.491, 0.173, 0.499, 0.23)
      ..cubicTo(0.554, 0.235, 0.612, 0.202, 0.647, 0.16)
      ..close();
    canvas.drawPath(mark, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_AppleMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
