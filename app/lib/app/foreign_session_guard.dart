import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

import '../shared/log/best_effort.dart';
import 'backend_target.dart';

/// Signs out, before the session gate starts, a session this install of the
/// app did not create (accounts ADR-0008). Two kinds reach a fresh start:
///
/// - **One from before an uninstall, on iOS.** Firebase Auth keeps the user in
///   the Keychain, which survives deleting the app, so a reinstall wakes up
///   signed in as whoever used the last install — on whatever backend that
///   build talked to. A marker file in Application Support, which *is* deleted
///   with the app, tells a reinstall from a relaunch. Android keeps the user in
///   the app's own data, which goes with the app, so it needs no marker.
/// - **One the emulator issued, on a cloud build.** Installing a cloud build
///   over an emulator build keeps the emulator's user. Its ID token is unsigned
///   (`alg: none`), which no real backend issues, so it is recognised from the
///   cached token without asking anybody.
///
/// Everything else — a real session the backend has since refused — is the
/// session check's to find (`AuthGateway.checkSession`). Best-effort: a
/// failure here is logged and the start carries on, because the check behind
/// it still catches a dead session, only later.
Future<void> forgetForeignSession(FirebaseAuth auth, BackendTarget target) =>
    bestEffort(
      'foreign session guard',
      code: 'guard-failed',
      run: () async {
        if (Platform.isIOS && !await _markInstall()) {
          await auth.signOut();
          return;
        }
        final user = auth.currentUser;
        if (target != BackendTarget.cloud || user == null) return;
        // `false`: the cached token, not a refresh. Bounded because an expired
        // one is refreshed over the network, and this runs before first frame.
        final token = await user.getIdToken().timeout(_tokenTimeout);
        if (token != null && _isUnsigned(token)) await auth.signOut();
      },
    );

const _tokenTimeout = Duration(seconds: 3);
const _markerName = '.nestprep-install';

/// Whether this install had already started once. Leaves the marker behind,
/// so the answer is false exactly once per install.
Future<bool> _markInstall() async {
  final directory = await getApplicationSupportDirectory();
  final marker = File('${directory.path}/$_markerName');
  if (marker.existsSync()) return true;
  await marker.create(recursive: true);
  return false;
}

/// Whether a JWT's header says it carries no signature — what the Auth
/// emulator issues and no real backend does.
bool _isUnsigned(String token) {
  final header = token.split('.').first;
  final decoded = utf8.decode(base64Url.decode(base64Url.normalize(header)));
  final json = jsonDecode(decoded);
  return json is Map<String, Object?> && json['alg'] == 'none';
}
