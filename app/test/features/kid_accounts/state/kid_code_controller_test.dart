import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/kid_accounts/state/kid_code_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_kid_sign_in.dart';

/// The kid's way in (accounts ADR-0003): what a child types becomes a code,
/// the code becomes a token, and the token becomes a session.
void main() {
  late FakeKidSignInDirectory directory;
  late FakeAuthGateway auth;
  late KidCodeController controller;

  setUp(() {
    directory = FakeKidSignInDirectory();
    auth = FakeAuthGateway();
    controller = KidCodeController(
      kidSignInDirectory: directory,
      authGateway: auth,
    );
  });

  tearDown(() async {
    controller.dispose();
    await auth.close();
  });

  group('what a child types', () {
    test('is upper-cased, as the code is printed', () {
      expect(KidCodeController.normalise('abc234'), 'ABC234');
    });

    test('keeps only letters a code can have — no 0/O, no 1/I/L', () {
      expect(KidCodeController.normalise('a-b c0O1Il9'), 'ABC9');
    });

    test('stops at six', () {
      expect(KidCodeController.normalise('ABCDEFGH'), 'ABCDEF');
    });
  });

  test('cannot be sent until the code is whole', () async {
    controller.setCode('ABC23');
    expect(controller.isComplete, isFalse);
    await controller.submit();
    expect(directory.redeemed, isEmpty);
  });

  test('redeems the code and signs in with the token it gets back', () async {
    directory.token = 'minted';
    controller.setCode('abc234');

    await controller.submit();

    expect(directory.redeemed, ['ABC234']);
    expect(auth.kidTokens, ['minted']);
    expect(controller.failure, isNull);
    expect(controller.isSubmitting, isFalse);
  });

  test('sends once, however many times the button is pressed', () async {
    directory.holdCalls = Completer<void>();
    controller.setCode('ABC234');

    final first = controller.submit();
    expect(controller.isSubmitting, isTrue);
    await controller.submit();
    directory.holdCalls!.complete();
    await first;

    expect(directory.redeemed, hasLength(1));
  });

  test('a refused code is kept for the screen, and typing clears it', () async {
    directory.failWith = const KidSignInFailure(KidSignInProblem.codeExpired);
    controller.setCode('ABC234');

    await controller.submit();

    expect(
      controller.failure,
      isA<KidSignInFailure>().having(
        (failure) => failure.problem,
        'problem',
        KidSignInProblem.codeExpired,
      ),
    );
    expect(auth.kidTokens, isEmpty);

    controller.setCode('ABC23');
    expect(controller.failure, isNull);
  });

  test('a sign-in that fails after the code was spent says so too', () async {
    auth.failSignInWith = const SignInFailure(SignInProblem.networkUnavailable);
    controller.setCode('ABC234');

    await controller.submit();

    expect(controller.failure, isA<SignInFailure>());
  });
}
