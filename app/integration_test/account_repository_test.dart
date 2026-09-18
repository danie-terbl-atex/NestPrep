import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/features/accounts/data/firestore_account_repository.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';

import 'household_fixture.dart';

/// The account repository against the real Firestore (ADR-0010).
///
/// `ensureAccount` runs on **every** sign-in and has the two-path shape that
/// already produced one serious bug in this repo: it creates when the document is
/// absent and updates when it is not. The update is a field update precisely so
/// that `householdIds` and `activeHouseholdId` survive — those are written only
/// by a Cloud Function (household ADR-0002), and the account has no business
/// touching them.
///
/// If that update ever became a `set`, signing in again would silently empty the
/// account's household list: the person opens the app, is signed in, and their
/// household is gone. Nothing in a unit test sees that, because the write shape
/// is the bug.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestHousehold home;
  late FirestoreAccountRepository accounts;

  setUpAll(() async {
    home = await signInAndCreateAHousehold();
    accounts = FirestoreAccountRepository(home.firestore);
  });

  tearDownAll(() async => home.signOut());

  String uid() => FirebaseAuth.instance.currentUser!.uid;

  AuthUser signedInAs({String? displayName, String? photoUrl}) => AuthUser(
    uid: uid(),
    email: 'tester@example.invalid',
    displayName: displayName,
    photoUrl: photoUrl,
  );

  test('the account exists after creating a household', () async {
    // The callable added the household to `users/{uid}` server-side, so this
    // client's cache does not have it yet and `.first` would hand back the
    // snapshot from before. Wait to be told.
    final account = await accounts
        .watch(uid())
        .firstWhere(
          (Account? value) => value?.householdIds.contains(home.id) ?? false,
        )
        .timeout(const Duration(seconds: 10));

    expect(account, isNotNull);
    expect(account!.householdIds, contains(home.id));
  });

  test('signing in again keeps the household list', () async {
    // The one that matters. `ensureAccount` must not be able to undo what a
    // Function wrote.
    final before = await accounts
        .watch(uid())
        .firstWhere((Account? value) => value?.householdIds.isNotEmpty ?? false)
        .timeout(const Duration(seconds: 10));
    expect(before!.householdIds, isNotEmpty);

    await accounts.ensureAccount(signedInAs(displayName: 'Tester'));

    final after = (await accounts.watch(uid()).first)!;
    expect(
      after.householdIds,
      before.householdIds,
      reason: 'a sign-in must never empty the account of its households',
    );
    expect(after.activeHouseholdId, before.activeHouseholdId);
  });

  test('it refreshes the name and picture from the provider', () async {
    await accounts.ensureAccount(
      signedInAs(displayName: 'Renamed', photoUrl: 'https://example.invalid/a'),
    );

    final account = await accounts
        .watch(uid())
        .firstWhere((Account? value) => value?.displayName == 'Renamed')
        .timeout(const Duration(seconds: 10));

    expect(account!.photoUrl, 'https://example.invalid/a');
  });

  test('with no display name it falls back to the email local part', () async {
    // `bestName`, on the real write path rather than in isolation.
    await accounts.ensureAccount(signedInAs());

    final account = await accounts
        .watch(uid())
        .firstWhere((Account? value) => value?.displayName == 'tester')
        .timeout(const Duration(seconds: 10));

    expect(account, isNotNull);
  });

  test('a second sign-in stamps lastSignedInAt', () async {
    await accounts.ensureAccount(signedInAs(displayName: 'Tester'));

    final account = await accounts
        .watch(uid())
        .firstWhere((Account? value) => value?.lastSignedInAt != null)
        .timeout(const Duration(seconds: 10));

    expect(account!.lastSignedInAt, isNotNull);
  });

  test('switching the active household writes only that field', () async {
    final before = (await accounts.watch(uid()).first)!;

    await accounts.setActiveHousehold(uid: uid(), householdId: home.id);

    final after = (await accounts.watch(uid()).first)!;
    expect(after.activeHouseholdId, home.id);
    expect(
      after.householdIds,
      before.householdIds,
      reason: 'switching households is not joining or leaving one',
    );
  });

  test('another account cannot be written', () async {
    // The rules own this, and it is worth one case here because it is the whole
    // reason the account document is keyed by uid.
    await expectLater(
      accounts.setActiveHousehold(uid: 'somebody-else', householdId: home.id),
      throwsA(isA<Object>()),
    );
  });
}
