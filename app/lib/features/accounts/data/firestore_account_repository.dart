import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/log/app_log.dart';
import '../model/account.dart';
import '../model/auth_user.dart';
import 'account_repository.dart';

final class FirestoreAccountRepository implements AccountRepository {
  FirestoreAccountRepository(FirebaseFirestore firestore)
    : _accounts = typedCollection(
        firestore.collection(collectionPath),
        fromJson: Account.fromJson,
        toJson: (account) => account.toJson(),
      );

  static const collectionPath = 'users';

  final CollectionReference<Account> _accounts;

  @override
  Stream<Account?> watch(String uid) => _accounts
      .doc(uid)
      .snapshots()
      .map((snapshot) => snapshot.data())
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> ensureAccount(AuthUser user) async {
    try {
      final document = _accounts.doc(user.uid);
      final existing = await document.get();
      if (!existing.exists) {
        // A new account belongs to no household and has none active; only a
        // Function may change that (household ADR-0002), and the rules only
        // allow a create that says so.
        await document.set(
          Account(
            id: user.uid,
            displayName: user.bestName,
            photoUrl: user.photoUrl,
          ),
        );
        return;
      }
      // Refreshing an existing account is not something the session waits on.
      // A write's future completes only when the server acknowledges it, so
      // awaiting this offline — or with a token the backend is refusing —
      // holds the gate for ever (vault lesson on writes against an unreachable
      // backend). It is queued, syncs when the connection is back, and a
      // refusal is logged rather than lost (`ENG-10`).
      unawaited(
        document
            .update({
              'displayName': user.bestName,
              'photoUrl': user.photoUrl,
              'lastSignedInAt': FieldValue.serverTimestamp(),
            })
            .catchError((Object error) {
              AppLog.failure(
                'account refresh',
                code: error is FirebaseException ? error.code : 'unknown',
                error: error,
              );
            }),
      );
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<void> setActiveHousehold({
    required String uid,
    required String householdId,
  }) async {
    try {
      await _accounts.doc(uid).update({'activeHouseholdId': householdId});
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<void> acceptLegal({
    required String uid,
    required int termsVersion,
    required int privacyVersion,
  }) async {
    try {
      await _accounts.doc(uid).update({
        'legalConsent': {
          'termsVersion': termsVersion,
          'privacyVersion': privacyVersion,
          'acceptedAt': FieldValue.serverTimestamp(),
        },
      });
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
