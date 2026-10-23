import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/welcome_tour/model/tour_version.dart';
import 'package:nestprep/features/welcome_tour/state/tour_seen_recorder.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_auth.dart';

/// Recording on the account that the tour was seen (welcome-tour ADR-0001).
void main() {
  late FakeAccountRepository accounts;

  setUp(() => accounts = FakeAccountRepository());
  tearDown(() => accounts.close());

  test('records the version this build shows', () async {
    TourSeenRecorder(
      accountRepository: accounts,
      signedInUid: () => 'uid-sam',
    ).markSeen();
    await pumpEventQueue();
    expect(accounts.seenTours, [TourVersion.current]);
    expect(TourVersion.current, 2, reason: 'the spotlight tour is version 2');
  });

  test('a refused write is logged, not thrown at the person leaving', () async {
    accounts.failWritesWith = const PermissionDeniedFailure();
    TourSeenRecorder(
      accountRepository: accounts,
      signedInUid: () => 'uid-sam',
    ).markSeen();
    await pumpEventQueue();
    expect(accounts.seenTours, isEmpty);
  });

  test('records nothing without an account to record it on', () async {
    TourSeenRecorder(
      accountRepository: accounts,
      signedInUid: () => '',
    ).markSeen();
    await pumpEventQueue();
    expect(accounts.seenTours, isEmpty);
  });
}
