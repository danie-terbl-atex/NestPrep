import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/documents/state/offline_copy_janitor.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_document_tools.dart';

/// Offline copies never outlive the right to them (documents ADR-0007):
/// signing out, another account on the phone, leaving a household and the
/// switch going off each delete what they should — and only that.
void main() {
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;
  late FakeFeatureFlagSource flagSource;
  late FeatureFlagsController flags;
  late InMemoryOfflineCopyStore store;
  late OfflineCopyJanitor janitor;

  final bytes = Uint8List.fromList([1, 2, 3]);

  setUp(() async {
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
    flagSource = FakeFeatureFlagSource();
    flags = FeatureFlagsController(source: flagSource);
    store = InMemoryOfflineCopyStore();
    await store.save('uid-sam', anOfflineCopy('a'), bytes);
    await store.save('uid-sam', anOfflineCopy('b', householdId: 'h2'), bytes);
    await store.save('uid-alex', anOfflineCopy('c'), bytes);
    janitor = OfflineCopyJanitor(store: store, session: session, flags: flags);
  });

  tearDown(() async {
    janitor.dispose();
    session.dispose();
    flags.dispose();
    await auth.close();
    await accounts.close();
    await flagSource.close();
  });

  Future<void> settle() async {
    for (var turn = 0; turn < 5; turn++) {
      await Future<void>.delayed(Duration.zero);
    }
    await janitor.settled;
  }

  /// The account arrives after the session has started watching for it,
  /// as it does from Firestore.
  Future<void> signInAsSam({
    List<String> households = const ['h1', 'h2'],
  }) async {
    auth.emit(const AuthUser(uid: 'uid-sam', email: 'sam@nestprep.test'));
    await settle();
    accounts.emit(
      Account(id: 'uid-sam', displayName: 'Sam', householdIds: households),
    );
  }

  test(
    'touches nothing before anybody is known to be signed in or out',
    () async {
      await settle();
      expect(store.byAccount.keys, containsAll(['uid-sam', 'uid-alex']));
    },
  );

  test('signed in: every other account on the phone is deleted', () async {
    await signInAsSam();
    await settle();

    expect(store.byAccount.keys, ['uid-sam']);
    expect(await store.list('uid-sam'), hasLength(2));
  });

  test('a household left or removed from takes its copies with it', () async {
    await signInAsSam(households: const ['h1']);
    await settle();

    final kept = await store.list('uid-sam');
    expect(kept.map((copy) => copy.householdId), ['h1']);
  });

  test('signing out deletes everything on the phone', () async {
    await signInAsSam();
    await settle();
    auth.emit(null);
    await settle();

    expect(store.byAccount, isEmpty);
  });

  test('before the switches have answered, a release default deletes '
      'nothing — only the document turning it off does', () async {
    janitor.dispose();
    flags.dispose();
    flags = FeatureFlagsController(source: flagSource, defaultOn: false);
    janitor = OfflineCopyJanitor(store: store, session: session, flags: flags);

    await signInAsSam();
    await settle();
    expect(await store.list('uid-sam'), hasLength(2));

    flagSource.emit({'documentOfflineCopies': true});
    await settle();
    expect(await store.list('uid-sam'), hasLength(2));

    flagSource.emit({'documentOfflineCopies': false});
    await settle();
    expect(store.byAccount, isEmpty);
  });

  test('switching offline copies off deletes them, signed in or not', () async {
    await signInAsSam();
    await settle();

    flagSource.emit({'documentOfflineCopies': false});
    await settle();

    expect(store.byAccount, isEmpty);
  });
}
