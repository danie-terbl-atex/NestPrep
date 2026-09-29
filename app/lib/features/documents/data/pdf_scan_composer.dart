import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/failure/app_failure.dart';
import 'scan_composer.dart';

/// The scan pipeline: decode each side, scale it so its long edge is at most
/// [maxEdge] pixels, re-encode it as JPEG at [jpegQuality], and lay each on a
/// PDF page of its own shape (documents ADR-0004).
///
/// Two phone photos are 4–8 MB; composed, a two-sided ID card is a few hundred
/// kilobytes and its small print is still legible. The work runs in a
/// background isolate, because decoding a 12-megapixel photo on the UI thread
/// is a frozen screen.
final class PdfScanComposer implements ScanComposer {
  const PdfScanComposer();

  static const maxEdge = 2000;
  static const jpegQuality = 75;

  /// A page's width in PDF points: A4's, so a printed scan is a sensible size.
  static const pageWidthPoints = 595.0;

  @override
  Future<Uint8List> compose(List<Uint8List> pages) async {
    final composed = await Isolate.run(() => composeNow(pages));
    if (composed == null) {
      throw const DocumentFailure(DocumentProblem.cannotRender);
    }
    return composed;
  }

  /// The pipeline itself, on whatever thread calls it. Null when a page is
  /// not an image — the isolate cannot carry an `AppFailure` back.
  static Future<Uint8List?> composeNow(List<Uint8List> pages) async {
    final document = pw.Document();
    for (final page in pages) {
      final compressed = compressPage(page);
      if (compressed == null) return null;
      _addPage(document, compressed);
    }
    return document.save();
  }

  /// One side, upright, scaled down to [maxEdge] and re-encoded; null when
  /// the bytes are not an image.
  static CompressedPage? compressPage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    var upright = img.bakeOrientation(decoded);
    final longEdge = upright.width > upright.height
        ? upright.width
        : upright.height;
    if (longEdge > maxEdge) {
      upright = upright.width >= upright.height
          ? img.copyResize(
              upright,
              width: maxEdge,
              interpolation: img.Interpolation.average,
            )
          : img.copyResize(
              upright,
              height: maxEdge,
              interpolation: img.Interpolation.average,
            );
    }
    return CompressedPage(
      jpeg: img.encodeJpg(upright, quality: jpegQuality),
      width: upright.width,
      height: upright.height,
    );
  }

  static void _addPage(pw.Document document, CompressedPage page) {
    final height = pageWidthPoints * page.height / page.width;
    document.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          pageWidthPoints,
          pageWidthPoints,
        ).copyWith(height: height),
        build: (context) => pw.Image(pw.MemoryImage(page.jpeg)),
      ),
    );
  }
}

/// One side after compression: the JPEG and the size it was drawn at.
class CompressedPage {
  const CompressedPage({
    required this.jpeg,
    required this.width,
    required this.height,
  });

  final Uint8List jpeg;
  final int width;
  final int height;
}
