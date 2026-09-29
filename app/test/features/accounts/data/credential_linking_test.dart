import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/data/credential_linking.dart';

/// One person is one account (accounts ADR-0002).
///
/// This is the class that keeps that true, and the thing it guards against is
/// invisible until it is far too late: a second uid holds a second set of
/// household memberships, and no screen in this app can merge them. So the
/// rules it enforces are pinned here rather than trusted.
///
/// `linkTo` needs a real `User`, which needs a platform channel, so what is
/// tested here is everything up to the call — what is remembered, what is
/// refused, and what is forgotten. The link itself is covered on a device.
void main() {
  AuthCredential googleCredential() =>
      GoogleAuthProvider.credential(idToken: 'id-token');

  test('a refusal carrying a credential and an address is remembered', () {
    final linking = CredentialLinking();
    linking.remember(
      FirebaseAuthException(
        code: 'account-exists-with-different-credential',
        email: 'sam@nestprep.test',
        credential: googleCredential(),
      ),
    );
    expect(linking.pendingEmail, 'sam@nestprep.test');
  });

  test('a refusal with no credential leaves nothing pending', () {
    // `email-already-in-use` is the shape this hits: registering a password
    // over an address Google already has. There is nothing to link, and
    // pretending otherwise would leave the screen offering to join up two
    // things when it has only one.
    final linking = CredentialLinking();
    linking.remember(
      FirebaseAuthException(
        code: 'email-already-in-use',
        email: 'sam@nestprep.test',
      ),
    );
    expect(linking.pendingEmail, isNull);
  });

  test('a refusal with no address leaves nothing pending', () {
    // Without an address there is no way to check that the person who signs in
    // next is the same one — and linking to whoever turns up is the bug this
    // whole class exists to prevent.
    final linking = CredentialLinking();
    linking.remember(
      FirebaseAuthException(
        code: 'account-exists-with-different-credential',
        credential: googleCredential(),
      ),
    );
    expect(linking.pendingEmail, isNull);
  });

  test('signing out forgets what was pending', () {
    // On a shared phone the next person to sign in is somebody else, and a
    // credential that survived would be attached to their account.
    final linking = CredentialLinking();
    linking.remember(
      FirebaseAuthException(
        code: 'account-exists-with-different-credential',
        email: 'sam@nestprep.test',
        credential: googleCredential(),
      ),
    );
    linking.clear();
    expect(linking.pendingEmail, isNull);
  });
}
