import 'dart:io';

/// Where the Local Emulator Suite is reachable from the device running the app.
/// The Android emulator reaches the host machine on 10.0.2.2; everything else on
/// localhost. Override with `--dart-define=NESTPREP_EMULATOR_HOST=<ip>` for a
/// physical device on the same network. Ports mirror `firebase.json`.
class EmulatorEndpoint {
  const EmulatorEndpoint({required this.host, required this.firestorePort});

  static const hostDefineName = 'NESTPREP_EMULATOR_HOST';
  static const _definedHost = String.fromEnvironment(hostDefineName);
  static const _androidEmulatorHostLoopback = '10.0.2.2';
  static const _defaultFirestorePort = 8080;

  final String host;
  final int firestorePort;

  factory EmulatorEndpoint.forThisDevice() {
    final host = _definedHost.isNotEmpty
        ? _definedHost
        : Platform.isAndroid
        ? _androidEmulatorHostLoopback
        : 'localhost';
    return EmulatorEndpoint(host: host, firestorePort: _defaultFirestorePort);
  }
}
