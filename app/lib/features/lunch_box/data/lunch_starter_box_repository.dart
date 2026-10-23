import '../model/lunch_starter_box.dart';

/// NestPrep's ready-made boxes, read-only — the same for every household.
abstract interface class LunchStarterBoxRepository {
  /// The published boxes in their order, at most `LunchStarterBox.limit`.
  /// One this build cannot read is left out, never a failure.
  Future<List<LunchStarterBox>> fetchPublished();
}
