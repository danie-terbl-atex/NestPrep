import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/notifications/data/notification_repository.dart';
import 'package:nestprep/features/notifications/model/push_arrival.dart';
import 'package:nestprep/features/notifications/state/push_registrar.dart';
import 'package:nestprep/features/notifications/state/turn_on_notifications.dart';
import 'package:nestprep/features/notifications/ui/first_open_push_prompt.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_notifications.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/notifications_fixtures.dart';

void main() {
  late FakeNotificationRepository repository;

  setUp(() => repository = FakeNotificationRepository());
  tearDown(() => repository.close());

  Future<(PushRegistrar, FakePushGateway)> pump(
    WidgetTester tester, {
    required PushPermission current,
    String memberId = Fixtures.samMemberId,
    bool start = true,
  }) async {
    final (registrar, phone, _) = NotificationFixtures.registrar(
      gateway: FakePushGateway(current: current),
    );
    addTearDown(registrar.dispose);
    addTearDown(phone.close);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PushRegistrar>.value(value: registrar),
          Provider<NotificationRepository>.value(value: repository),
        ],
        child: FirstOpenPushPrompt(
          owner: NotificationsOwner(
            householdId: Fixtures.householdId,
            memberId: memberId,
            isFamily: true,
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    if (start) await registrar.start();
    await tester.pumpAndSettle();
    return (registrar, phone);
  }

  testWidgets('a phone that was never asked is asked once, on first open', (
    tester,
  ) async {
    final (registrar, phone) = await pump(
      tester,
      current: PushPermission.notAsked,
    );

    expect(phone.prompts, 1);
    expect(registrar.permission, PushPermission.granted);
    expect(repository.saved.single.digest.enabled, isTrue);
  });

  testWidgets('before the phone has answered, nothing is asked', (
    tester,
  ) async {
    final (_, phone) = await pump(
      tester,
      current: PushPermission.notAsked,
      start: false,
    );
    expect(phone.prompts, 0);
  });

  for (final answered in [PushPermission.granted, PushPermission.denied]) {
    testWidgets('a phone that already said ${answered.name} is not asked', (
      tester,
    ) async {
      final (_, phone) = await pump(tester, current: answered);
      expect(phone.prompts, 0);
      expect(repository.saved, isEmpty);
    });
  }

  testWidgets('with nobody to write the choices for, nothing is asked', (
    tester,
  ) async {
    final (_, phone) = await pump(
      tester,
      current: PushPermission.notAsked,
      memberId: '',
    );
    expect(phone.prompts, 0);
  });
}
