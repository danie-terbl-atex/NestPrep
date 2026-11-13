import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// The PDF stays on the phone: only pictures of its pages are sent, and the
/// bytes go when the import screen does (recipes ADR-0009).
@immutable
final class PickedPdf {
  const PickedPdf({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;

  /// "DOUGH IT EASY (1).pdf" is "DOUGH IT EASY".
  static String nameOf(String fileName) {
    final bare = fileName
        .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*\(\d+\)$'), '')
        .trim();
    return bare.isEmpty ? RecipeDocumentCopy.untitled : bare;
  }
}

abstract interface class RecipePdfPicker {
  /// Null when the member backed out.
  Future<PickedPdf?> pick();
}

final class FileSelectorRecipePdfPicker implements RecipePdfPicker {
  const FileSelectorRecipePdfPicker();

  static const maxBytes = 100 * 1024 * 1024;

  static const _pdfs = XTypeGroup(
    label: RecipeDocumentCopy.pickerLabel,
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
    uniformTypeIdentifiers: ['com.adobe.pdf'],
  );

  @override
  Future<PickedPdf?> pick() async {
    try {
      final file = await openFile(acceptedTypeGroups: const [_pdfs]);
      if (file == null) return null;
      if (await file.length() > maxBytes) {
        throw const OwnRecipeFailure(OwnRecipeProblem.documentTooLarge);
      }
      return PickedPdf(
        bytes: await file.readAsBytes(),
        name: PickedPdf.nameOf(file.name),
      );
    } on PlatformException catch (error) {
      AppLog.failure('recipe pdf picker', code: error.code, error: error);
      throw const OwnRecipeFailure(OwnRecipeProblem.documentPickerUnavailable);
    }
  }
}

/// A page as the platform drew it: premultiplied RGBA, transparent where the
/// PDF draws nothing.
@immutable
final class PdfRasterPage {
  const PdfRasterPage({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;
  final Uint8List rgba;
}

abstract interface class PdfRasterizer {
  /// [pages] count from 0; null is every page.
  Stream<PdfRasterPage> raster(Uint8List pdf, List<int>? pages, double dpi);
}

/// PDFKit on iOS and PdfRenderer on Android, through `printing`.
final class PrintingPdfRasterizer implements PdfRasterizer {
  const PrintingPdfRasterizer();

  @override
  Stream<PdfRasterPage> raster(Uint8List pdf, List<int>? pages, double dpi) =>
      Printing.raster(pdf, pages: pages, dpi: dpi).map(
        (page) => PdfRasterPage(
          width: page.width,
          height: page.height,
          rgba: page.pixels,
        ),
      );
}
