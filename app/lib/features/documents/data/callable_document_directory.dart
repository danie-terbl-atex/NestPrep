import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'document_directory.dart';
import 'document_failure_mapper.dart';

final class CallableDocumentDirectory implements DocumentDirectory {
  const CallableDocumentDirectory(this._functions, this._auth);

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  @override
  Future<void> syncAccess() async {
    await _call('syncDocumentAccess', const {});
    // The Function wrote the claim; this is what puts it on the token in this
    // app's hands. Without the refresh the next Storage call still carries the
    // old one, which for somebody who has just joined means no claim at all.
    await _auth.currentUser?.getIdToken(true);
  }

  @override
  Future<void> deleteFolder({
    required String householdId,
    required String folderId,
  }) async {
    await _call('deleteDocumentFolder', {
      'householdId': householdId,
      'folderId': folderId,
    });
  }

  Future<void> _call(String name, Map<String, Object?> payload) async {
    try {
      await _functions.httpsCallable(name).call<Object?>(payload);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromDocumentCallable(error);
    }
  }
}
