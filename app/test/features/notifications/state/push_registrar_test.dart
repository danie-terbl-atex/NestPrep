import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/notifications/model/push_arrival.dart';
import 'package:nestprep/features/notifications/model/push_token.dart';
import 'package:nestprep/features/notifications/state/push_registrar.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_notifications.dart';

/// This phone's part of the channel (notifications ADR-0001, ADR-0003): it
/// never asks by itself, registers only with a yes, follows the token and the
/// session, and forgets the phone on sign-out.
void main() {
  late FakePushGateway gateway;
  late FakePushTokenRepository tokens;
  late ValueNotifier<String> session;
  late PushRegistrar registrar;

  setUp(() {
    gateway = FakePushGateway();
    tokens = FakePushTokenRepository();
    session = ValueNotifier('uid-sam');
    registrar = PushRegistrar(
      gateway: gateway,
      tokens: tokens,
      session: session,
      signedInUid: () => session.value,
    );
  });

  tearDown(() async {
    registrar.dispose();
    session.dispose();
    await gateway.close();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starting asks nobody anything, and makes the four channels', () async {
    await registrar.start();
    expect(gateway.prompts, 0);
    expect(registrar.permission, PushPermission.notAsked);
    expect(tokens.registered, isEmpty);
    expect(gateway.channels.map((channel) => channel.id), [
      'nestprep_digest',
      'nestprep_documents',
      'nestprep_handover',
      'nestprep_chores',
    ]);
    expect(gateway.channels.first.name, 'Morning digest');
  });

  test('a phone that already said yes is registered quietly', () async {
    gateway.current = PushPermission.granted;
    await registrar.start();
    expect(gateway.prompts, 0);
    expect(tokens.registered.single, (
      'uid-sam',
      PushToken.of('token-1', PushPlatform.android),
    ));
    expect(registrar.isReachable, isTrue);
  });

  test('turning on asks once, and a yes registers the phone', () async {
    await registrar.start();
    expect(await registrar.turnOn(), PushPermission.granted);
    expect(gateway.prompts, 1);
    expect(tokens.registered.single.$1, 'uid-sam');
    expect(registrar.isReachable, isTrue);
  });

  test('a no registers nothing, and says so', () async {
    gateway.answer = PushPermission.denied;
    await registrar.start();
    expect(await registrar.turnOn(), PushPermission.denied);
    expect(tokens.registered, isEmpty);
    expect(registrar.isReachable, isFalse);
  });

  test('a phone with no token to give is allowed but not reachable', () async {
    gateway
      ..current = PushPermission.granted
      ..phoneToken = null;
    await registrar.start();
    expect(registrar.permission, PushPermission.granted);
    expect(registrar.isReachable, isFalse);
  });

  test('a new token is registered the moment the service rotates it', () async {
    gateway.current = PushPermission.granted;
    await registrar.start();
    gateway.rotateToken('token-2');
    await settle();
    expect(tokens.registered.last.$2.token, 'token-2');
  });

  test('signing out forgets the phone; the next person registers it', () async {
    gateway.current = PushPermission.granted;
    await registrar.start();
    session.value = '';
    await settle();
    expect(gateway.forgets, 1);
    expect(registrar.isReachable, isFalse);
    session.value = 'uid-pat';
    await settle();
    expect(tokens.registered.last.$1, 'uid-pat');
  });

  test(
    'a refused registration leaves the phone unreachable, not broken',
    () async {
      gateway.current = PushPermission.granted;
      tokens.failWith = const PermissionDeniedFailure();
      await registrar.start();
      expect(registrar.permission, PushPermission.granted);
      expect(registrar.isReachable, isFalse);
    },
  );
}
