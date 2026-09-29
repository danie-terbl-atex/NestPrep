import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/model/session.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_auth.dart';
import '../../../support/household_fixtures.dart';

const _sam = AuthUser(
  uid: Fixtures.samUid,
  email: 'sam@nestprep.test',
  displayName: 'Sam Parent',
);

Account account({
  List<String> householdIds = const [],
  String? activeHouseholdId,
}) => Account(
  id: Fixtures.samUid,
  displayName: 'Sam Parent',
  householdIds: householdIds,
  activeHouseholdId: activeHouseholdId,
);

void main() {
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController controller;

  setUp(() {
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    controller = SessionController(
      authGateway: auth,
      accountRepository: accounts,
    );
  });

  tearDown(() async {
    controller.dispose();
    await auth.close();
    await accounts.close();
  });

  Session sessionOf() {
    final state = controller.session;
    expect(state, isA<AsyncData<Session>>());
    return (state as AsyncData<Session>).value;
  }

  test('starts not knowing who is using the app', () {
    expect(controller.session, isA<AsyncLoading<Session>>());
    expect(controller.activeHouseholdId, isNull);
    expect(controller.uidOrEmpty, isEmpty);
  });

  test('nobody signed in is an answer, not a loading state', () async {
    auth.emit(null);
    await pumpEventQueue();
    expect(sessionOf(), isA<SignedOut>());
  });

  test(
    'signing in writes the account document before the session is ready',
    () async {
      auth.emit(_sam);
      await pumpEventQueue();
      expect(accounts.ensured, [Fixtures.samUid]);
      // The document has not come back through the listener yet.
      expect(controller.session, isA<AsyncLoading<Session>>());

      accounts.emit(account());
      await pumpEventQueue();
      expect(sessionOf(), isA<SignedIn>());
    },
  );

  test(
    'does not flash signed-out while the account document is on its way',
    () async {
      auth.emit(_sam);
      await pumpEventQueue();
      accounts.emit(null);
      await pumpEventQueue();
      expect(controller.session, isA<AsyncLoading<Session>>());
    },
  );

  test(
    'the active household is the chosen one while it is still ours',
    () async {
      auth.emit(_sam);
      await pumpEventQueue();
      accounts.emit(
        account(householdIds: ['h1', 'h2'], activeHouseholdId: 'h2'),
      );
      await pumpEventQueue();
      expect(controller.activeHouseholdId, 'h2');
    },
  );

  test(
    'a household left on another device falls back to one we still belong to',
    () async {
      auth.emit(_sam);
      await pumpEventQueue();
      accounts.emit(account(householdIds: ['h1'], activeHouseholdId: 'gone'));
      await pumpEventQueue();
      expect(controller.activeHouseholdId, 'h1');
    },
  );

  test('belonging to no household is null, not an empty string', () async {
    auth.emit(_sam);
    await pumpEventQueue();
    accounts.emit(account());
    await pumpEventQueue();
    expect(controller.activeHouseholdId, isNull);
  });

  test('switching to the household already showing asks for nothing', () async {
    auth.emit(_sam);
    await pumpEventQueue();
    accounts.emit(account(householdIds: ['h1', 'h2'], activeHouseholdId: 'h1'));
    await pumpEventQueue();

    await controller.switchHousehold('h1');
    expect(accounts.activeHouseholds, isEmpty);
  });

  test('switching to another household writes it once', () async {
    auth.emit(_sam);
    await pumpEventQueue();
    accounts.emit(account(householdIds: ['h1', 'h2'], activeHouseholdId: 'h1'));
    await pumpEventQueue();

    await controller.switchHousehold('h2');
    // The account document has not come back yet, so a second ask would be the
    // same write — and the screen is already on its way.
    await controller.switchHousehold('h2');
    expect(accounts.activeHouseholds, ['h2', 'h2']);
  });

  test(
    'backing out of the Google sheet is not a failure worth showing',
    () async {
      auth.failSignInWith = const SignInFailure(SignInProblem.cancelled);
      await controller.signInWithGoogle();
      expect(controller.signInFailure, isNull);
      expect(controller.isSigningIn, isFalse);
    },
  );

  test('a sign-in that really failed becomes copy', () async {
    auth.failSignInWith = const SignInFailure(SignInProblem.notConfigured);
    await controller.signInWithGoogle();
    expect(controller.signInFailure, isA<SignInFailure>());
  });

  test(
    'a session the backend no longer accepts signs the person out',
    () async {
      auth.emit(_sam);
      await pumpEventQueue();
      accounts.failStreamWith(const SessionExpiredFailure());
      await pumpEventQueue();

      // Signed out, with copy that says why — not a retry on a read that can
      // never succeed.
      expect(auth.signOutCount, 1);
      expect(controller.signInFailure, isA<SessionExpiredFailure>());
    },
  );

  test(
    'any other read failure offers a retry instead of signing out',
    () async {
      auth.emit(_sam);
      await pumpEventQueue();
      accounts.failStreamWith(const UnavailableFailure());
      await pumpEventQueue();

      expect(auth.signOutCount, 0);
      expect(controller.session, isA<AsyncFailure<Session>>());
    },
  );

  test('signing out ends the session', () async {
    auth.emit(_sam);
    await pumpEventQueue();
    accounts.emit(account());
    await pumpEventQueue();

    await controller.signOut();
    await pumpEventQueue();
    expect(sessionOf(), isA<SignedOut>());
    expect(auth.signOutCount, 1);
  });

  group('proving the address', () {
    test('nobody signed in has nothing to prove', () async {
      auth.emit(null);
      await pumpEventQueue();
      expect(
        controller.emailVerified,
        isTrue,
        reason:
            'false here would route a signed-out person at the verify '
            'screen, which is a loop with no way out',
      );
    });

    test('a signed-in account reports what its credential says', () async {
      auth.emit(_sam);
      await pumpEventQueue();
      accounts.emit(account());
      await pumpEventQueue();

      expect(
        controller.emailVerified,
        isFalse,
        reason: 'AuthUser defaults to unverified, so the gate fails closed',
      );
    });

    test(
      'verifying rebuilds the session, so the gate actually opens',
      () async {
        auth.emit(_sam);
        await pumpEventQueue();
        accounts.emit(account());
        await pumpEventQueue();
        expect(controller.emailVerified, isFalse);

        // What opening the link in another app looks like from in here.
        auth.emailIsVerified = true;
        final verified = await controller.refreshEmailVerified();
        await pumpEventQueue();
        accounts.emit(account());
        await pumpEventQueue();

        expect(verified, isTrue);
        expect(
          controller.emailVerified,
          isTrue,
          reason:
              'the token the callables read has changed; a session still '
              'holding the old one keeps the gate shut for somebody through it',
        );
      },
    );

    test('an unverified check leaves the session where it was', () async {
      auth.emit(_sam);
      await pumpEventQueue();
      accounts.emit(account());
      await pumpEventQueue();

      expect(await controller.refreshEmailVerified(), isFalse);
      expect(controller.emailVerified, isFalse);
    });

    test('a failed send is kept for the screen, not thrown', () async {
      auth.emit(_sam);
      await pumpEventQueue();
      accounts.emit(account());
      await pumpEventQueue();

      auth.failSendWith = const SignInFailure(SignInProblem.tooManyAttempts);
      await controller.resendVerificationEmail();

      expect(controller.signInFailure, isA<SignInFailure>());
    });
  });
}
