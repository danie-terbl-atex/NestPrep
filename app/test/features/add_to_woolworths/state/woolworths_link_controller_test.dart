import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_woolworths/state/woolworths_link_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_woolworths.dart';

void main() {
  late FakeWoolworthsDirectory directory;
  late FakeWoolworthsSignIn signIn;

  WoolworthsLinkController controller() {
    final made = WoolworthsLinkController(directory: directory, signIn: signIn);
    addTearDown(made.dispose);
    return made;
  }

  setUp(() {
    directory = FakeWoolworthsDirectory();
    signIn = FakeWoolworthsSignIn();
  });

  test('opening reads the status and signs in to nothing', () async {
    final link = controller();
    await pumpEventQueue();
    expect(link.step, WoolworthsLinkStep.account);
    expect(directory.starts, 0);
    expect(signIn.signIns, isEmpty);
  });

  test('signs in on the phone and hands over only the refresh token', () async {
    final link = controller();
    await pumpEventQueue();
    final linked = await link.signIn(
      email: ' sam@example.com ',
      password: 'secret',
    );
    expect(linked, isTrue);
    expect(link.step, WoolworthsLinkStep.linked);
    expect(signIn.signIns.single, (
      email: 'sam@example.com',
      password: 'secret',
    ));
    expect(directory.completions, [FakeWoolworthsSignIn.refreshToken]);
  });

  test('a code Woolworths sends is asked for, then it is linked', () async {
    signIn.asksForCode = true;
    final link = controller();
    await pumpEventQueue();
    expect(await link.signIn(email: 'a@b.co', password: 'p'), isFalse);
    expect(link.step, WoolworthsLinkStep.code);
    expect(link.codeSentTo, '+27*****4567');
    expect(directory.completions, isEmpty);

    expect(await link.verify(' 123456 '), isTrue);
    expect(signIn.answers, ['123456']);
    expect(link.step, WoolworthsLinkStep.linked);
  });

  test('a wrong password and a wrong code belong to their fields', () async {
    signIn.signInFailure = const WoolworthsFailure(
      WoolworthsProblem.wrongSignIn,
    );
    final link = controller();
    await pumpEventQueue();
    await link.signIn(email: 'a@b.co', password: 'p');
    expect(link.fieldFailure, isA<WoolworthsFailure>());
    expect(link.actionFailure, isNull);

    signIn
      ..signInFailure = null
      ..asksForCode = true
      ..answerFailure = const WoolworthsFailure(WoolworthsProblem.wrongCode);
    await link.signIn(email: 'a@b.co', password: 'p');
    await link.verify('000000');
    expect(link.step, WoolworthsLinkStep.code);
    expect(link.fieldFailure, isA<WoolworthsFailure>());
  });

  test('a sign-in that ran out goes back to the start, said above', () async {
    signIn
      ..asksForCode = true
      ..answerFailure = const WoolworthsFailure(
        WoolworthsProblem.signInExpired,
      );
    final link = controller();
    await pumpEventQueue();
    await link.signIn(email: 'a@b.co', password: 'p');
    await link.verify('123456');
    expect(link.step, WoolworthsLinkStep.account);
    expect(link.actionFailure, isA<WoolworthsFailure>());
  });

  test('the switch off is said before anything goes to Woolworths', () async {
    directory.startFailure = const WoolworthsFailure(
      WoolworthsProblem.featureOff,
    );
    final link = controller();
    await pumpEventQueue();
    await link.signIn(email: 'a@b.co', password: 'p');
    expect(signIn.signIns, isEmpty);
    expect(link.actionFailure, isA<WoolworthsFailure>());
  });

  test('a token the server cannot use is not linked', () async {
    directory.completeFailure = const WoolworthsFailure(
      WoolworthsProblem.linkRejected,
    );
    final link = controller();
    await pumpEventQueue();
    expect(await link.signIn(email: 'a@b.co', password: 'p'), isFalse);
    expect(link.step, WoolworthsLinkStep.account);
    expect(link.actionFailure, isA<WoolworthsFailure>());
  });

  test('unlinking forgets the link', () async {
    final link = controller();
    await pumpEventQueue();
    await link.signIn(email: 'a@b.co', password: 'p');
    await link.unlink();
    expect(directory.unlinks, 1);
    expect(link.step, WoolworthsLinkStep.account);
  });
}
