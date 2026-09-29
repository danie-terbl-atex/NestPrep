import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/app_router.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/kid_routes.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/model/kid_identity.dart';
import 'package:nestprep/features/accounts/model/session.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/register_screen.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';
import 'package:nestprep/shared/async/async_state.dart';

import '../../../support/fake_auth.dart';
import '../../../support/household_fixtures.dart';

/// A kid device's session (accounts ADR-0003): recognised by its claim, never
/// given an account document, and kept on its one screen.
void main() {
  const kid = KidIdentity(
    householdId: Fixtures.householdId,
    memberId: Fixtures.kidMemberId,
  );
  const tablet = AuthUser(uid: 'kid_tablet', email: '', kid: kid);

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

  group('the kid claim on a token', () {
    test('names the household and the profile', () {
      expect(
        KidIdentity.fromClaims({
          'kidProfile': {'householdId': 'h1', 'memberId': 'm-kid'},
        }),
        const KidIdentity(householdId: 'h1', memberId: 'm-kid'),
      );
    });

    test('is absent for every adult', () {
      expect(KidIdentity.fromClaims({'email_verified': true}), isNull);
      expect(KidIdentity.fromClaims(null), isNull);
    });

    test('is parsed, so a claim of the wrong shape is not a kid', () {
      for (final claim in <Object?>[
        'h1/m-kid',
        {'householdId': 'h1'},
        {'householdId': '', 'memberId': 'm-kid'},
        {'householdId': 1, 'memberId': 'm-kid'},
      ]) {
        expect(KidIdentity.fromClaims({'kidProfile': claim}), isNull);
      }
    });
  });

  test(
    'a kid device is a kid session, and writes no account document',
    () async {
      auth.emit(tablet);
      await pumpEventQueue();

      final state = session.session;
      expect(state, isA<AsyncData<Session>>());
      final value = (state as AsyncData<Session>).value;
      expect(value, isA<KidSignedIn>());
      expect(session.kidIdentity, kid);
      expect(accounts.ensured, isEmpty);
      expect(session.activeHouseholdId, isNull);
    },
  );

  test('signing out takes it back to signed out', () async {
    auth.emit(tablet);
    await pumpEventQueue();
    await session.signOut();
    await pumpEventQueue();
    expect(session.kidIdentity, isNull);
  });

  group('where the router lets a kid device be', () {
    setUp(() async {
      auth.emit(tablet);
      await pumpEventQueue();
    });

    test('its home, and only its home', () {
      expect(redirectForSession(session, KidRoute.homePath), isNull);
    });

    for (final location in [
      SignInScreen.path,
      KidRoute.codePath,
      HouseholdRoute.homeFor(Fixtures.householdId),
      HouseholdRoute.householdPathFor(Fixtures.householdId),
      KidRoute.managePathFor(Fixtures.householdId),
      '/households/somewhere-else/week',
    ]) {
      test('not $location', () {
        expect(redirectForSession(session, location), KidRoute.homePath);
      });
    }
  });

  group('signed out', () {
    setUp(() async {
      auth.emit(null);
      await pumpEventQueue();
    });

    test('the kid way in is one of the ways in', () {
      expect(redirectForSession(session, KidRoute.codePath), isNull);
      expect(redirectForSession(session, RegisterScreen.path), isNull);
    });

    test('and the kid home is not', () {
      expect(redirectForSession(session, KidRoute.homePath), SignInScreen.path);
    });
  });
}
