import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'pdf_page_renderer.dart';

/// `printing`'s rasteriser — PDFium on Android, PDFKit on iOS — from bytes in
/// memory, a page at a time (documents ADR-0004).
final class PrintingPdfPageRenderer implements PdfPageRenderer {
  const PrintingPdfPageRenderer();

  /// Sharp on a phone screen without holding a poster-sized bitmap per page.
  static const dotsPerInch = 144.0;

  /// A household document is a few pages; a 300-page manual is not what the
  /// vault is for, and rendering it would exhaust memory.
  static const maxPages = 20;

  @override
  Future<List<Uint8List>> render(Uint8List pdf) async {
    try {
      final pages = <Uint8List>[];
      final rasters = Printing.raster(pdf, dpi: dotsPerInch).take(maxPages);
      await for (final page in rasters) {
        pages.add(await page.toPng());
      }
      if (pages.isEmpty) {
        throw const DocumentFailure(DocumentProblem.cannotRender);
      }
      return pages;
    } on PlatformException catch (error) {
      AppLog.failure('pdf render', code: error.code, error: error);
      throw const DocumentFailure(DocumentProblem.cannotRender);
    }
  }
}
