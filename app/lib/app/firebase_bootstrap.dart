import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'backend_target.dart';
import 'emulator_endpoint.dart';
import 'emulator_firebase_options.dart';
import 'firebase_options.dart';

/// Initialises Firebase for the chosen target and returns the one Firestore
/// instance the app injects everywhere. Offline persistence is on: Firestore's
/// cache is the app's only local store (foundation ADR-0006).
Future<FirebaseFirestore> bootstrapFirebase(BackendTarget target) async {
  switch (target) {
    case BackendTarget.emulator:
      await Firebase.initializeApp(options: emulatorFirebaseOptions());
      final endpoint = EmulatorEndpoint.forThisDevice();
      final firestore = FirebaseFirestore.instance
        ..useFirestoreEmulator(endpoint.host, endpoint.firestorePort);
      return _withPersistence(firestore);
    case BackendTarget.cloud:
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return _withPersistence(FirebaseFirestore.instance);
  }
}

FirebaseFirestore _withPersistence(FirebaseFirestore firestore) {
  firestore.settings = const Settings(persistenceEnabled: true);
  return firestore;
}
