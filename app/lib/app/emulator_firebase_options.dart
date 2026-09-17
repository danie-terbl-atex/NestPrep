import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

/// Options for a `demo-` project id, which the Local Emulator Suite accepts
/// without any cloud project existing. Nothing here is a credential.
const emulatorProjectId = 'demo-nestprep';

FirebaseOptions emulatorFirebaseOptions() => FirebaseOptions(
  apiKey: 'emulator',
  appId: Platform.isIOS
      ? '1:000000000000:ios:0000000000000000'
      : '1:000000000000:android:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: emulatorProjectId,
);
