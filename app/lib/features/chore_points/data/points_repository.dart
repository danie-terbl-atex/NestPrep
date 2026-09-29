import '../../../shared/time/calendar_date.dart';
import '../model/point_balance.dart';
import '../model/point_claim.dart';
import '../model/point_entry.dart';

/// A child's stars as Firestore holds them (todos ADR-0003) — read only.
///
/// Balances, claims and ledger lines are written by Functions and nothing
/// else, so this interface has no writes at all: there is no way for the app
/// to give anybody a star, which is the point.
abstract interface class PointsRepository {
  /// Every child's balance — a household has a handful.
  Stream<List<PointBalance>> watchBalances(String householdId);

  /// One child's balance, or [PointBalance.none] before their first star. A
  /// kid device reads only its own (the rules refuse a sibling's).
  Stream<PointBalance> watchBalance(String householdId, String memberId);

  /// Chores waiting for a parent to look.
  Stream<List<PointClaim>> watchPendingClaims(String householdId);

  /// One child's claims for chores on or after [from] — what their jobs list
  /// needs to say "waiting for a grown-up" or "have another go".
  Stream<List<PointClaim>> watchClaimsFor(
    String householdId,
    String memberId, {
    required CalendarDate from,
  });

  /// One child's latest ledger lines, newest first.
  Stream<List<PointEntry>> watchEntriesFor(String householdId, String memberId);

  /// Bounds every read that could grow (`BE-08`).
  static const pendingLimit = 100;
  static const historyLimit = 30;
}
