import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/documents/data/pdf_scan_composer.dart';
import 'package:nestprep/features/documents/model/document_limits.dart';

/// The scan pipeline, with real image bytes (documents ADR-0004): two sides of
/// a card become one compressed PDF, each side scaled down to a size whose
/// print is still legible and whose bytes a phone contract can afford.
void main() {
  /// A side bigger than the pipeline keeps, with enough detail that JPEG has
  /// something to compress. Smaller than a real 12-megapixel photo only so the
  /// suite stays quick; the scaling is the same.
  Uint8List cameraSide({int width = 2600, int height = 1950, int seed = 0}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(240, 240, 235));
    // Lines of "print", so there is detail to keep and to compress.
    for (var y = 40 + seed; y < height; y += 60) {
      img.fillRect(
        image,
        x1: 60,
        y1: y,
        x2: width - 60 - (y % 400),
        y2: y + 18,
        color: img.ColorRgb8(30, 30, 40),
      );
    }
    return img.encodeJpg(image, quality: 95);
  }

  int pagesIn(Uint8List pdf) =>
      RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(pdf)).length;

  test('a side is scaled so its long edge is at most 2000 pixels', () {
    final landscape = PdfScanComposer.compressPage(cameraSide())!;
    expect(landscape.width, PdfScanComposer.maxEdge);
    expect(landscape.height, 1500);

    final portrait = PdfScanComposer.compressPage(
      cameraSide(width: 900, height: 2700),
    )!;
    expect(portrait.height, PdfScanComposer.maxEdge);
    expect(portrait.width, 667);
  });

  test('a side already small enough is not blown up', () {
    final small = PdfScanComposer.compressPage(
      cameraSide(width: 800, height: 500),
    )!;
    expect((small.width, small.height), (800, 500));
  });

  test('front and back become one PDF with a page each, smaller than the '
      'photos', () async {
    final front = cameraSide();
    final back = cameraSide(seed: 1);

    final pdf = (await PdfScanComposer.composeNow([front, back]))!;

    expect(latin1.decode(pdf.sublist(0, 5)), '%PDF-');
    expect(pagesIn(pdf), 2);
    // The sides are kept as JPEG inside the PDF, not re-inflated to pixels.
    expect(latin1.decode(pdf), contains('/DCTDecode'));
    expect(pdf.length, lessThan(front.length + back.length));
    expect(pdf.length, lessThan(DocumentLimits.maxSizeBytes));
  });

  test('bytes that are not a picture are refused, not filed', () async {
    final notAnImage = Uint8List.fromList(utf8.encode('definitely not a jpeg'));
    expect(PdfScanComposer.compressPage(notAnImage), isNull);
    expect(
      await PdfScanComposer.composeNow([
        cameraSide(width: 100, height: 60),
        notAnImage,
      ]),
      isNull,
    );
  });
}
