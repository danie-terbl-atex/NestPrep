import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/notifications/data/notification_directory.dart';
import 'package:nestprep/features/notifications/model/notification_settings.dart';
import 'package:nestprep/features/notifications/model/notification_vocabulary.dart';
import 'package:nestprep/features/notifications/model/push_arrival.dart';
import 'package:nestprep/features/notifications/state/notification_settings_controller.dart';
import 'package:nestprep/features/notifications/state/push_registrar.dart';
import 'package:nestprep/features/notifications/state/turn_on_notifications.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_notifications.dart';
import '../../../support/household_fixtures.dart';

/// A person's choices (notifications ADR-0003): every change is one write of
/// the whole document with the slot derived from it; the first yes writes the
/// defaults; family switches a child's digest; a test push says what happened.
void main() {
  late FakeNotificationRepository repository;
  late FakeNotificationDirectory directory;
  late FakePushGateway gateway;
  late ValueNotifier<String> session;
  late PushRegistrar registrar;

  setUp(() {
    repository = FakeNotificationRepository();
    directory = FakeNotificationDirectory();
    gateway = FakePushGateway();
    session = ValueNotifier(Fixtures.samUid);
    registrar = PushRegistrar(
      gateway: gateway,
      tokens: FakePushTokenRepository(),
      session: session,
      signedInUid: () => session.value,
    );
  });

  tearDown(() async {
    registrar.dispose();
    session.dispose();
    await gateway.close();
    await repository.close();
  });

  NotificationSettingsController controllerFor({bool isFamily = true}) =>
      NotificationSettingsController(
        repository: repository,
        directory: directory,
        registrar: registrar,
        owner: NotificationsOwner(
          householdId: Fixtures.householdId,
          memberId: Fixtures.samMemberId,
          isFamily: isFamily,
        ),
        kids: [Fixtures.kid],
      );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  NotificationSettings current(NotificationSettingsController controller) =>
      (controller.settings as AsyncData<NotificationSettings>).value;

  test('somebody who never chose sees the defaults, not a blank', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    await settle();
    expect(current(controller), NotificationSettings.unchosen('m-sam'));
  });

  test('two changes faster than the listener both land — neither undoes the '
      'other', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    await settle();
    await Future.wait([
      controller.setDigest(enabled: true),
      controller.setCategory(SwitchableCategory.chores, false),
    ]);
    final saved = repository.saved.last;
    expect(saved.digest.enabled, isTrue);
    expect(saved.wants(SwitchableCategory.chores), isFalse);
    expect(current(controller).digest.enabled, isTrue);
  });

  test(
    'turning the digest on at 07:10 saves 07:00 — the quarter hour',
    () async {
      final controller = controllerFor();
      addTearDown(controller.dispose);
      await settle();
      await controller.setDigest(enabled: true);
      await controller.setDigest(minute: 7 * 60 + 10);
      final saved = repository.saved.last;
      expect(saved.digest, const DigestChoice(enabled: true, minute: 420));
      expect(saved.digestSlot, 28);
      expect(saved.updatedBy, 'm-sam');
    },
  );

  test('switching a reminder off and quiet hours round saves each', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    await settle();
    await controller.setCategory(SwitchableCategory.handover, false);
    await controller.setQuietHours(start: 22 * 60, end: 5 * 60);
    final saved = repository.saved.last;
    expect(saved.wants(SwitchableCategory.handover), isFalse);
    expect(saved.quietHours.startMinute, 22 * 60);
    expect(saved.quietHours.endMinute, 5 * 60);
  });

  test('a refused save is held for the screen, not thrown', () async {
    final controller = controllerFor();
    addTearDown(controller.dispose);
    await settle();
    repository.failWritesWith = const PermissionDeniedFailure();
    await controller.setDigest(enabled: true);
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
  });

  test(
    'family switches a child’s digest, stamped with their own name',
    () async {
      final controller = controllerFor();
      addTearDown(controller.dispose);
      await settle();
      expect(controller.kids, [Fixtures.kid]);
      await controller.setKidDigest(Fixtures.kidMemberId, true);
      await settle();
      await settle();
      final saved = repository.settingsOf(Fixtures.kidMemberId);
      expect(saved?.digest.enabled, isTrue);
      expect(saved?.updatedBy, 'm-sam');
      expect(
        controller.kidSettings(Fixtures.kidMemberId).digest.enabled,
        isTrue,
      );
    },
  );

  test('a helper is not offered anybody else’s switches', () async {
    final controller = controllerFor(isFamily: false);
    addTearDown(controller.dispose);
    expect(controller.kids, isEmpty);
  });

  test(
    'the first yes writes the defaults; a later one leaves choices alone',
    () async {
      final controller = controllerFor();
      addTearDown(controller.dispose);
      expect(await controller.turnOn(), PushPermission.granted);
      final first = repository.settingsOf('m-sam');
      expect(first?.digest.enabled, isTrue);
      expect(first?.digest.minute, DigestTimes.defaultMinute);

      repository.setSettings(first!.copyWith(digest: const DigestChoice()));
      await controller.turnOn();
      expect(repository.settingsOf('m-sam')?.digest.enabled, isFalse);
    },
  );

  test('a no writes nothing', () async {
    gateway.answer = PushPermission.denied;
    final controller = controllerFor();
    addTearDown(controller.dispose);
    expect(await controller.turnOn(), PushPermission.denied);
    expect(repository.saved, isEmpty);
  });

  test(
    'a test push says what happened, and cannot be sent twice at once',
    () async {
      directory.outcome = TestPushOutcome.noDevice;
      final controller = controllerFor();
      addTearDown(controller.dispose);
      final first = controller.sendTest();
      final second = controller.sendTest();
      await Future.wait([first, second]);
      expect(directory.sentFor, [Fixtures.householdId]);
      expect(controller.testOutcome, TestPushOutcome.noDevice);
      expect(controller.isSendingTest, isFalse);
    },
  );
}
