import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/app_router.dart';
import 'package:nestprep/app/design_gallery_access.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/model/legal_consent.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/session_gate_screen.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';
import 'package:nestprep/features/accounts/ui/verify_email_screen.dart';
import 'package:nestprep/features/household/ui/household_gate_screen.dart';
import 'package:nestprep/features/legal/model/legal_versions.dart';
import 'package:nestprep/features/legal/ui/about_screen.dart';
import 'package:nestprep/features/legal/ui/consent_screen.dart';
import 'package:nestprep/features/legal/ui/legal_document_screen.dart';
import 'package:nestprep/features/legal/ui/licences_screen.dart';

import '../support/fake_auth.dart';
import '../support/household_fixtures.dart';

/// Who the router lets in, and where it sends everybody else.
///
/// `redirectForSession` was marked `@visibleForTesting` and then never tested,
/// which is how the design gallery's availability could change underneath it
/// without anything noticing.
void main() {
  const gallery = '/design';
  const somewhereInside = '/households/${Fixtures.householdId}/groceries';

  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;

  setUp(() {
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
  });

  tearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
  });

  /// Drives the controller to a signed-in account with the given households.
  ///
  /// The two emits cannot be back to back: the controller only subscribes to the
  /// account document *after* `ensureAccount` resolves, and both fakes are
  /// broadcast streams, so an account emitted before that subscription exists is
  /// simply lost and the session sits on loading for ever.
  ///
  /// [emailVerified] defaults to true because a Google credential always is,
  /// and Google is how most people arrive (accounts ADR-0002).
  Future<void> signIn({
    List<String> households = const [],
    bool emailVerified = true,
    LegalConsent? consent = FakeAccountRepository.currentConsent,
  }) async {
    auth.emit(
      AuthUser(
        uid: Fixtures.samUid,
        email: 'sam@nestprep.test',
        emailVerified: emailVerified,
      ),
    );
    await pumpEventQueue();
    accounts.emit(
      Account(
        id: Fixtures.samUid,
        displayName: 'Sam Parent',
        householdIds: households,
        activeHouseholdId: households.isEmpty ? null : households.first,
        legalConsent: consent,
      ),
      consented: false,
    );
    await pumpEventQueue();
  }

  Future<void> signOut() async {
    auth.emit(null);
    await pumpEventQueue();
  }

  test('the gallery is exempt, whatever the session is doing', () {
    // A debug build — which every test is — carries it.
    expect(DesignGalleryAccess.isAvailable, isTrue);
    expect(redirectForSession(session, gallery), isNull);
  });

  test('a session that has not answered yet waits in the gate', () {
    expect(
      redirectForSession(session, somewhereInside),
      SessionGateScreen.path,
    );
    expect(redirectForSession(session, SessionGateScreen.path), isNull);
  });

  test('signed out, only the sign-in screen exists', () async {
    await signOut();
    expect(redirectForSession(session, somewhereInside), SignInScreen.path);
    expect(redirectForSession(session, SignInScreen.path), isNull);
  });

  test('signed in with no household, only the household gate', () async {
    await signIn();
    expect(
      redirectForSession(session, somewhereInside),
      HouseholdGateScreen.path,
    );
    expect(redirectForSession(session, HouseholdGateScreen.path), isNull);
  });

  test('signed in with an unproved address and no household, only the confirm '
      'screen', () async {
    await signIn(emailVerified: false);
    // The household gate is the dead end this replaces: createHousehold and
    // redeemInvite both refuse an unverified caller, so sending them there
    // would be sending them somewhere nothing works.
    expect(
      redirectForSession(session, HouseholdGateScreen.path),
      VerifyEmailScreen.path,
    );
    expect(
      redirectForSession(session, somewhereInside),
      VerifyEmailScreen.path,
    );
    expect(redirectForSession(session, VerifyEmailScreen.path), isNull);
  });

  test('an unproved address already in a household is left alone', () async {
    // They joined through Google, or before the rule existed. Locking them out
    // of a household they are already in would punish them for our change, so
    // the gate only stands between an account and its first household.
    await signIn(
      households: const [Fixtures.householdId],
      emailVerified: false,
    );
    expect(redirectForSession(session, somewhereInside), isNull);
  });

  test(
    'signed in with a household, the waiting rooms hand over to it',
    () async {
      await signIn(households: const [Fixtures.householdId]);
      final home = HouseholdRoute.homeFor(Fixtures.householdId);
      for (final waitingRoom in [
        SessionGateScreen.path,
        SignInScreen.path,
        HouseholdGateScreen.path,
      ]) {
        expect(redirectForSession(session, waitingRoom), home);
      }
      expect(redirectForSession(session, somewhereInside), isNull);
    },
  );

  test("somebody else's household hands back to your own", () async {
    await signIn(households: const [Fixtures.householdId]);
    expect(
      redirectForSession(session, '/households/not-yours/groceries'),
      HouseholdRoute.homeFor(Fixtures.householdId),
    );
  });

  test('every tab of your own household is left alone', () async {
    await signIn(households: const [Fixtures.householdId]);
    for (final tab in HouseholdTab.values) {
      expect(
        redirectForSession(
          session,
          HouseholdRoute.pathFor(Fixtures.householdId, tab),
        ),
        isNull,
        reason: '${tab.name} is inside the household',
      );
    }
  });

  group('consent (accounts ADR-0005)', () {
    const readable = [
      AboutScreen.path,
      LegalDocumentScreen.privacyPath,
      LegalDocumentScreen.termsPath,
      LicencesScreen.path,
      '${LicencesScreen.path}/provider',
    ];

    test('never agreed: only the consent step and what it links to', () async {
      await signIn(households: const [Fixtures.householdId], consent: null);
      for (final location in [
        somewhereInside,
        HouseholdGateScreen.path,
        SessionGateScreen.path,
      ]) {
        expect(
          redirectForSession(session, location),
          ConsentScreen.path,
          reason: location,
        );
      }
      expect(redirectForSession(session, ConsentScreen.path), isNull);
      for (final location in readable) {
        expect(redirectForSession(session, location), isNull, reason: location);
      }
    });

    test('before the address or the household gate is even asked', () async {
      await signIn(emailVerified: false, consent: null);
      expect(
        redirectForSession(session, VerifyEmailScreen.path),
        ConsentScreen.path,
      );
    });

    test('an older version is asked again', () async {
      await signIn(
        households: const [Fixtures.householdId],
        consent: const LegalConsent(
          termsVersion: LegalVersions.terms - 1,
          privacyVersion: LegalVersions.privacy,
        ),
      );
      expect(redirectForSession(session, somewhereInside), ConsentScreen.path);
      expect(session.hasAcceptedEarlierLegal, isTrue);
    });

    test('the current version lets them through, and off the step', () async {
      await signIn(households: const [Fixtures.householdId]);
      expect(redirectForSession(session, somewhereInside), isNull);
      expect(
        redirectForSession(session, ConsentScreen.path),
        HouseholdRoute.homeFor(Fixtures.householdId),
      );
    });

    test('agreed with no household, the step hands over to the gate', () async {
      await signIn();
      expect(
        redirectForSession(session, ConsentScreen.path),
        HouseholdGateScreen.path,
      );
    });

    test('signed out, the consent step is not a way in', () async {
      await signOut();
      expect(
        redirectForSession(session, ConsentScreen.path),
        SignInScreen.path,
      );
    });
  });
}
