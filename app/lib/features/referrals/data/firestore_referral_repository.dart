import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/household_referral.dart';
import '../model/premium_grant.dart';
import '../model/referral_line.dart';
import 'referral_repository.dart';

final class FirestoreReferralRepository implements ReferralRepository {
  FirestoreReferralRepository(this._firestore);

  static const householdsPath = 'households';
  static const referralPath = 'referral';
  static const currentReferral = 'current';
  static const historyPath = 'referralHistory';
  static const grantsPath = 'premiumGrants';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  @override
  Stream<HouseholdReferral> watchReferral(String householdId) =>
      typedCollection(
            _household(householdId).collection(referralPath),
            fromJson: HouseholdReferral.fromJson,
            toJson: (referral) => referral.toJson(),
          )
          .doc(currentReferral)
          .snapshots()
          .map((snapshot) => snapshot.data() ?? HouseholdReferral.none)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<ReferralLine>> watchHistory(String householdId) =>
      typedCollection(
            _household(householdId).collection(historyPath),
            fromJson: ReferralLine.fromJson,
            toJson: (line) => line.toJson(),
          )
          .orderBy('redeemedAt', descending: true)
          .limit(ReferralRepository.lineLimit)
          .snapshots()
          .map((snapshot) => [for (final line in snapshot.docs) line.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<PremiumGrant>> watchGrants(String householdId) =>
      typedCollection(
            _household(householdId).collection(grantsPath),
            fromJson: PremiumGrant.fromJson,
            toJson: (grant) => grant.toJson(),
          )
          .orderBy('grantedAt', descending: true)
          .limit(ReferralRepository.lineLimit)
          .snapshots()
          .map((snapshot) => [for (final grant in snapshot.docs) grant.data()])
          .handleError((Object error) => throw failureFromFirebase(error));
}
