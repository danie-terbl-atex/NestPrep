import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/app_router.dart';
import 'package:nestprep/features/account_data/ui/account_centre_screen.dart';
import 'package:nestprep/features/account_data/ui/account_export_screen.dart';
import 'package:nestprep/features/account_data/ui/delete_account_screen.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/model/legal_consent.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';

import '../support/fake_auth.dart';
import '../support/household_fixtures.dart';

/// The account centre is open to anybody signed in, whatever else is
/// unfinished (accounts ADR-0006): both stores require that deleting an
/// account is never behind another step, and somebody who will not agree to
/// new terms must still be able to leave.
void main() {
  const accountPlaces = [
    AccountCentreScreen.path,
    AccountExportScreen.path,
    DeleteAccountScreen.path,
  ];

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

  void expectOpen(String reason) {
    for (final place in accountPlaces) {
      expect(
        redirectForSession(session, place),
        isNull,
        reason: '$reason: $place',
      );
    }
  }

  test('open inside a household', () async {
    await signIn(households: const [Fixtures.householdId]);
    expectOpen('in a household');
  });

  test('open with no household yet, instead of the household gate', () async {
    await signIn();
    expectOpen('no household');
  });

  test('open with an address not yet confirmed', () async {
    await signIn(emailVerified: false);
    expectOpen('unconfirmed address');
  });

  test(
    'open before the terms are agreed — declining must not trap anyone',
    () async {
      await signIn(households: const [Fixtures.householdId], consent: null);
      expectOpen('no consent');
    },
  );

  test('closed to somebody signed out', () async {
    auth.emit(null);
    await pumpEventQueue();
    for (final place in accountPlaces) {
      expect(redirectForSession(session, place), SignInScreen.path);
    }
  });
}
