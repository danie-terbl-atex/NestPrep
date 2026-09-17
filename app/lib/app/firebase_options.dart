import 'package:firebase_core/firebase_core.dart';

/// Placeholder until `flutterfire configure` overwrites this file with the
/// NestPrep cloud project's options. The project does not exist yet
/// (foundation ADR-0003); until it does, only the emulator target boots.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw StateError(
    'No cloud Firebase project is configured. Run `flutterfire configure` '
    'in app/ (see CLAUDE.md), or build with --dart-define=NESTPREP_BACKEND=emulator.',
  );
}
