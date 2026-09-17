import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
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
      await document.update({
        'displayName': user.bestName,
        'photoUrl': user.photoUrl,
        'lastSignedInAt': FieldValue.serverTimestamp(),
      });
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
}
