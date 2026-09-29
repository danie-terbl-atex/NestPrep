import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/weekly_numbers.dart';
import 'beta_numbers_repository.dart';

final class FirestoreBetaNumbersRepository implements BetaNumbersRepository {
  FirestoreBetaNumbersRepository(this._firestore, this._auth);

  static const weeksPath = 'analyticsWeeks';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<WeeklyNumbers> get _weeks => typedCollection(
    _firestore.collection(weeksPath),
    fromJson: WeeklyNumbers.fromJson,
    toJson: (numbers) => numbers.toJson(),
  );

  @override
  Stream<List<WeeklyNumbers>> watchRecentWeeks() => _weeks
      // The week key sorts as text in the order of time. It is the document
      // id too, but ordered by the field: Firestore refuses to scan document
      // ids in descending order, and the emulator says so where a test with a
      // fake repository never could.
      .orderBy('week', descending: true)
      .limit(BetaNumbersRepository.weekLimit)
      .snapshots()
      .map((snapshot) => [for (final week in snapshot.docs) week.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<bool> canRead() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult();
      return token.claims?[BetaNumbersRepository.readerClaim] == true;
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
