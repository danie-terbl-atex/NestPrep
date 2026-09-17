import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'backend_target.dart';
import 'emulator_endpoint.dart';
import 'firebase_options.dart';

/// The Firebase services the app injects, initialised for the chosen target.
class FirebaseServices {
  const FirebaseServices({
    required this.firestore,
    required this.auth,
    required this.functions,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseFunctions functions;
}

/// Initialises Firebase once from the project's own client configuration, then
/// points every service at the Local Emulator Suite when the build asks for it
/// (foundation ADR-0008).
///
/// The client configuration is the same on both targets because the Android
/// SDKs insist on it; what makes a build safe is that every service is
/// redirected *before* anything uses it, which is why the redirection happens
/// here and nowhere else. Offline persistence is on: Firestore's cache is the
/// app's only local store (foundation ADR-0006).
Future<FirebaseServices> bootstrapFirebase(BackendTarget target) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final functions = FirebaseFunctions.instance;

  if (target == BackendTarget.emulator) {
    final endpoint = EmulatorEndpoint.forThisDevice();
    firestore.useFirestoreEmulator(endpoint.host, endpoint.firestorePort);
    functions.useFunctionsEmulator(endpoint.host, endpoint.functionsPort);
    await auth.useAuthEmulator(endpoint.host, endpoint.authPort);
  }

  firestore.settings = const Settings(persistenceEnabled: true);
  return FirebaseServices(
    firestore: firestore,
    auth: auth,
    functions: functions,
  );
}
