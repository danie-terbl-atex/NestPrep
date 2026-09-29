import '../model/weekly_numbers.dart';

/// Where the Beta numbers screen reads from (product-analytics ADR-0001).
///
/// Only an account holding the reader claim may read these; `firestore.rules`
/// refuses everybody else, so a listener opened without it fails with a
/// permission failure rather than showing anything.
abstract interface class BetaNumbersRepository {
  /// The most recent weeks' totals, newest first.
  Stream<List<WeeklyNumbers>> watchRecentWeeks();

  /// Whether the signed-in account holds the reader claim — which decides
  /// whether the way in is offered at all. The rules decide whether the
  /// numbers are actually readable (`BE-20`).
  Future<bool> canRead();

  /// How many weeks the screen shows: a quarter, which spans the beta.
  static const weekLimit = 13;

  /// The custom claim `functions/tools/grant-analytics-reader.mjs` sets.
  static const readerClaim = 'analyticsReader';
}
