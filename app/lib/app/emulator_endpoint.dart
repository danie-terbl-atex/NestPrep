import 'dart:io';

/// Where the Local Emulator Suite is reachable from the device running the app.
/// The Android emulator reaches the host machine on 10.0.2.2; everything else on
/// localhost. Override with `--dart-define=NESTPREP_EMULATOR_HOST=<ip>` for a
/// physical device on the same network. Ports mirror `firebase.json`.
class EmulatorEndpoint {
  const EmulatorEndpoint({
    required this.host,
    required this.firestorePort,
    required this.authPort,
    required this.functionsPort,
  });

  static const hostDefineName = 'NESTPREP_EMULATOR_HOST';
  static const _definedHost = String.fromEnvironment(hostDefineName);
  static const _androidEmulatorHostLoopback = '10.0.2.2';
  static const _defaultFirestorePort = 8080;
  static const _defaultAuthPort = 9099;
  static const _defaultFunctionsPort = 5001;

  final String host;
  final int firestorePort;
  final int authPort;
  final int functionsPort;

  factory EmulatorEndpoint.forThisDevice() {
    final host = _definedHost.isNotEmpty
        ? _definedHost
        : Platform.isAndroid
        ? _androidEmulatorHostLoopback
        : 'localhost';
    return EmulatorEndpoint(
      host: host,
      firestorePort: _defaultFirestorePort,
      authPort: _defaultAuthPort,
      functionsPort: _defaultFunctionsPort,
    );
  }
}
