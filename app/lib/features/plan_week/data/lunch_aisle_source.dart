import '../model/aisle_shelf.dart';

/// Which shelves of Checkers' lunchbox aisle to read (lunch-box ADR-0013).
/// Behind an interface so a test decides without Firestore (`FE-20`).
abstract interface class LunchAisleSource {
  /// The shelves to read now — never empty: NestPrep's own list when nothing
  /// else says otherwise.
  Future<List<AisleShelf>> shelves();
}
