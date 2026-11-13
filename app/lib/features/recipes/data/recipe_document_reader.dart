import '../model/recipe_document.dart';

/// The two reads of a PDF (recipes ADR-0009): which recipes it holds, then one
/// of them in full. Only pictures of pages are sent; the PDF never is.
abstract interface class RecipeDocumentReader {
  Future<RecipeDocumentScan> scan({
    required String householdId,
    required String documentName,
    required List<DocumentScanPage> pages,
  });

  Future<DocumentRecipeReading> draft({
    required String householdId,
    required String documentName,
    required String recipeName,
    required List<DocumentReadPage> pages,
  });
}
