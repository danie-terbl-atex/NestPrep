import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:nestprep/features/recipes/data/recipe_document_reader.dart';
import 'package:nestprep/features/recipes/data/recipe_pdf.dart';
import 'package:nestprep/features/recipes/data/shared_pdf_inbox.dart';
import 'package:nestprep/features/recipes/model/recipe_document.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The picture work on the test's own isolate.
Future<R> workHere<M, R>(ComputeCallback<M, R> work, M message) async =>
    work(message);

final class FakeRecipePdfPicker implements RecipePdfPicker {
  PickedPdf? pdf = PickedPdf(
    bytes: Uint8List.fromList([1, 2, 3]),
    name: 'Dough it easy',
  );
  AppFailure? failWith;
  int picks = 0;

  @override
  Future<PickedPdf?> pick() async {
    picks++;
    if (failWith case final failure?) throw failure;
    return pdf;
  }
}

final class FakeSharedPdfInbox implements SharedPdfInbox {
  final filed = <String, PickedPdf>{};
  AppFailure? failWith;

  @override
  Future<PickedPdf?> take(String token) async {
    if (failWith case final failure?) throw failure;
    return filed.remove(token);
  }
}

/// Draws every page transparent, at the size the dpi gives it, and remembers
/// what it was asked for.
final class FakePdfRasterizer implements PdfRasterizer {
  FakePdfRasterizer({int pages = 3, Size size = const Size(600, 800)})
    : sizes = List.filled(pages, size);

  List<Size> sizes;
  Exception? failWith;
  final calls = <({List<int>? pages, double dpi})>[];

  @override
  Stream<PdfRasterPage> raster(
    Uint8List pdf,
    List<int>? pages,
    double dpi,
  ) async* {
    calls.add((pages: pages, dpi: dpi));
    if (failWith case final error?) throw error;
    for (final index
        in pages ?? [for (var at = 0; at < sizes.length; at++) at]) {
      final size = sizes[index];
      final width = (size.width * dpi / 72).round();
      final height = (size.height * dpi / 72).round();
      yield PdfRasterPage(
        width: width,
        height: height,
        rgba: Uint8List(width * height * 4),
      );
    }
  }

  List<({List<int>? pages, double dpi})> get drawn =>
      calls.where((call) => call.pages != null).toList();
}

final class FakeRecipeDocumentReader implements RecipeDocumentReader {
  RecipeDocumentScan scanAnswer = const RecipeDocumentScan(
    recipes: [],
    callsLeft: 90,
  );
  AppFailure? scanFailure;
  final draftAnswers = <String, DocumentRecipeReading>{};
  final draftFailures = <String, AppFailure>{};
  final scanned = <List<DocumentScanPage>>[];
  final drafted = <({String recipeName, List<DocumentReadPage> pages})>[];
  Completer<void>? holdDrafts;

  @override
  Future<RecipeDocumentScan> scan({
    required String householdId,
    required String documentName,
    required List<DocumentScanPage> pages,
  }) async {
    scanned.add(pages);
    if (scanFailure case final failure?) throw failure;
    return scanAnswer;
  }

  @override
  Future<DocumentRecipeReading> draft({
    required String householdId,
    required String documentName,
    required String recipeName,
    required List<DocumentReadPage> pages,
  }) async {
    drafted.add((recipeName: recipeName, pages: pages));
    await holdDrafts?.future;
    if (draftFailures.remove(recipeName) case final failure?) throw failure;
    return draftAnswers[recipeName] ??
        const DocumentRecipeReading(draft: null, photo: null, callsLeft: 80);
  }
}
