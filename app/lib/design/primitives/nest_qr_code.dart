import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_spacing.dart';
import 'nest_brand_mark.dart';

/// A QR code for another phone's camera to read off this screen, with the
/// NestPrep mark in the middle. Ink on Oat in both themes: a camera reads dark
/// on light, and a light code on a dark screen fails on half the phones that
/// try (household ADR-0012). The mark hides under a tenth of the modules and
/// level H error correction rebuilds up to 30%.
class NestQrCode extends StatefulWidget {
  const NestQrCode({
    required this.data,
    required this.semanticLabel,
    this.size = NestSize.qrCode,
    super.key,
  });

  final String data;
  final String semanticLabel;
  final double size;

  @override
  State<NestQrCode> createState() => _NestQrCodeState();
}

class _NestQrCodeState extends State<NestQrCode> {
  late QrImage _image = _encode(widget.data);

  static QrImage _encode(String data) => QrImage(
    QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.H),
  );

  @override
  void didUpdateWidget(NestQrCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _image = _encode(widget.data);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: widget.semanticLabel,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: NestColors.oat,
        borderRadius: BorderRadius.circular(NestRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NestSpace.lg),
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _QrPainter(_image),
        ),
      ),
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;
  final Paint _ink = Paint()..color = NestColors.inkBrand;

  static const _markShare = 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount;
    final module = size.width / count;
    final hole = _holeModules(count);
    final holeStart = (count - hole) ~/ 2;
    final holeEnd = holeStart + hole;
    bool inHole(int i) => i >= holeStart && i < holeEnd;
    final path = Path();
    for (var row = 0; row < count; row++) {
      for (var column = 0; column < count; column++) {
        if (!image.isDark(row, column)) continue;
        if (inHole(row) && inHole(column)) continue;
        path.addRect(
          Rect.fromLTWH(column * module, row * module, module, module),
        );
      }
    }
    canvas.drawPath(path, _ink);
    final mark = Rect.fromLTWH(
      holeStart * module,
      holeStart * module,
      hole * module,
      hole * module,
    ).deflate(module);
    canvas
      ..save()
      ..translate(mark.left, mark.top);
    const NestMarkPainter().paint(canvas, mark.size);
    canvas.restore();
  }

  static int _holeModules(int count) {
    final hole = (count * _markShare).round();
    return hole.isOdd ? hole : hole + 1;
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.image != image;
}
