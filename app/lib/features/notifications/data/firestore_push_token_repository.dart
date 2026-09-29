import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/push_token.dart';
import 'push_token_repository.dart';

final class FirestorePushTokenRepository implements PushTokenRepository {
  FirestorePushTokenRepository(this._firestore);

  static const path = 'pushTokens';

  final FirebaseFirestore _firestore;

  CollectionReference<PushToken> _tokens(String uid) => typedCollection(
    _firestore.collection('users').doc(uid).collection(path),
    fromJson: PushToken.fromJson,
    toJson: (token) => token.toJson(),
  );

  @override
  Future<void> register(String uid, PushToken token) async {
    try {
      await _tokens(uid).doc(token.id).set(token);
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
