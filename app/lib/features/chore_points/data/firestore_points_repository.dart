import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/point_balance.dart';
import '../model/point_claim.dart';
import '../model/point_entry.dart';
import 'points_repository.dart';

final class FirestorePointsRepository implements PointsRepository {
  FirestorePointsRepository(this._firestore);

  static const balancesPath = 'pointBalances';
  static const claimsPath = 'pointClaims';
  static const entriesPath = 'pointEntries';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(
    String householdId,
    String path,
  ) => _firestore.collection('households').doc(householdId).collection(path);

  CollectionReference<PointBalance> _balances(String householdId) =>
      typedCollection(
        _raw(householdId, balancesPath),
        fromJson: PointBalance.fromJson,
        toJson: (balance) => balance.toJson(),
      );

  CollectionReference<PointClaim> _claims(String householdId) =>
      typedCollection(
        _raw(householdId, claimsPath),
        fromJson: PointClaim.fromJson,
        toJson: (claim) => claim.toJson(),
      );

  CollectionReference<PointEntry> _entries(String householdId) =>
      typedCollection(
        _raw(householdId, entriesPath),
        fromJson: PointEntry.fromJson,
        toJson: (entry) => entry.toJson(),
      );

  @override
  Stream<List<PointBalance>> watchBalances(String householdId) =>
      _balances(householdId)
          .limit(PointsRepository.pendingLimit)
          .snapshots()
          .map(_docs)
          .handleError(_failed);

  @override
  Stream<PointBalance> watchBalance(String householdId, String memberId) =>
      _balances(householdId)
          .doc(memberId)
          .snapshots()
          .map((snapshot) => snapshot.data() ?? PointBalance.none(memberId))
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<PointClaim>> watchPendingClaims(String householdId) =>
      _claims(householdId)
          .where('status', isEqualTo: ClaimStatus.pending.name)
          .limit(PointsRepository.pendingLimit)
          .snapshots()
          .map(_docs)
          .handleError(_failed);

  @override
  Stream<List<PointClaim>> watchClaimsFor(
    String householdId,
    String memberId, {
    required CalendarDate from,
  }) => _claims(householdId)
      .where('memberId', isEqualTo: memberId)
      // A range on the date string, which sorts as the calendar does
      // (`ENG-21`).
      .where('occurrenceDate', isGreaterThanOrEqualTo: from.iso)
      .limit(PointsRepository.pendingLimit)
      .snapshots()
      .map(_docs)
      .handleError(_failed);

  @override
  Stream<List<PointEntry>> watchEntriesFor(
    String householdId,
    String memberId,
  ) => _entries(householdId)
      .where('memberId', isEqualTo: memberId)
      // Newest first by a field, never by the document id (the vault
      // lesson on descending key scans).
      .orderBy('at', descending: true)
      .limit(PointsRepository.historyLimit)
      .snapshots()
      .map(_docs)
      .handleError(_failed);

  static List<T> _docs<T>(QuerySnapshot<T> snapshot) => [
    for (final doc in snapshot.docs) doc.data(),
  ];

  static Never _failed(Object error) => throw failureFromFirebase(error);
}
