import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/legal/model/legal_versions.dart';
import 'package:nestprep/features/legal/state/consent_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_auth.dart';

/// The consent step's rules (accounts ADR-0005): both ticks before the
/// button, one write of this build's versions, and a failure to retry.
void main() {
  late FakeAccountRepository accounts;
  late ConsentController controller;

  setUp(() {
    accounts = FakeAccountRepository();
    controller = ConsentController(
      accountRepository: accounts,
      uid: 'uid-sam',
      isUpdate: false,
    );
  });

  tearDown(() async {
    controller.dispose();
    await accounts.close();
  });

  test('cannot accept until both are ticked', () async {
    expect(controller.canAccept, isFalse);
    await controller.accept();
    expect(accounts.acceptedLegal, isEmpty);

    controller.setAdult(value: true);
    expect(controller.canAccept, isFalse);
    controller.setAgreesToTerms(value: true);
    expect(controller.canAccept, isTrue);

    controller.setAdult(value: false);
    expect(controller.canAccept, isFalse, reason: 'unticking takes it back');
  });

  test('records the versions this build ships', () async {
    controller
      ..setAdult(value: true)
      ..setAgreesToTerms(value: true);
    await controller.accept();
    expect(accounts.acceptedLegal, hasLength(1));
    expect(accounts.acceptedLegal.single.termsVersion, LegalVersions.terms);
    expect(accounts.acceptedLegal.single.privacyVersion, LegalVersions.privacy);
    expect(controller.failure, isNull);
  });

  test('sends once, however often it is pressed', () async {
    controller
      ..setAdult(value: true)
      ..setAgreesToTerms(value: true);
    await Future.wait([controller.accept(), controller.accept()]);
    expect(accounts.acceptedLegal, hasLength(1));
  });

  test('a refused write is a failure to retry, not a way past', () async {
    controller
      ..setAdult(value: true)
      ..setAgreesToTerms(value: true);
    accounts.failWritesWith = const UnavailableFailure();
    await controller.accept();
    expect(controller.failure, isA<UnavailableFailure>());
    expect(controller.canAccept, isTrue);

    accounts.failWritesWith = null;
    await controller.accept();
    expect(controller.failure, isNull);
    expect(accounts.acceptedLegal, hasLength(1));
  });
}
