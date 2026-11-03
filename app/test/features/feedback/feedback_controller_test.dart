import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/feedback/model/feedback_draft.dart';
import 'package:nestprep/features/feedback/state/feedback_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../support/fake_feedback.dart';

void main() {
  late FakeFeedbackRepository repository;
  late FeedbackController controller;

  setUp(() {
    repository = FakeFeedbackRepository();
    controller = FeedbackController(
      repository: repository,
      uid: 'uid-sam',
      householdId: 'h1',
      screen: '/households/:householdId/lunch',
    );
  });

  tearDown(() => controller.dispose());

  test('cannot send until it has a kind and some words', () async {
    expect(controller.canSend, isFalse);
    controller.chooseKind(FeedbackKind.problem);
    expect(controller.canSend, isFalse);
    controller.setMessage('   ');
    expect(controller.canSend, isFalse);
    controller.setMessage('The list forgets ticks');
    expect(controller.canSend, isTrue);

    await controller.send();
    expect(repository.sent, hasLength(1));
  });

  test(
    'sends what the person chose, trimmed, with where they came from',
    () async {
      controller
        ..chooseKind(FeedbackKind.idea)
        ..chooseArea(FeedbackArea.groceries)
        ..setMessage('  A shared shop list per store  ')
        ..setMayContact(true);

      await controller.send();

      final sent = repository.sent.single;
      expect(sent.uid, 'uid-sam');
      expect(sent.draft.kind, FeedbackKind.idea);
      expect(sent.draft.area, FeedbackArea.groceries);
      expect(sent.draft.message, 'A shared shop list per store');
      expect(sent.draft.mayContact, isTrue);
      expect(sent.draft.householdId, 'h1');
      expect(sent.draft.screen, '/households/:householdId/lunch');
      expect(controller.status, FeedbackStatus.delivered);
    },
  );

  test('words without a kind are not enough', () async {
    controller.setMessage('Something about something');
    expect(controller.canSend, isFalse);

    await controller.send();
    expect(repository.sent, isEmpty);
  });

  test('choosing the same area again clears it', () {
    controller
      ..chooseArea(FeedbackArea.lunch)
      ..chooseArea(FeedbackArea.lunch);
    expect(controller.area, isNull);
  });

  test('says it is queued when the server has not answered', () async {
    repository.delivery = FeedbackDelivery.queued;
    controller
      ..chooseKind(FeedbackKind.praise)
      ..setMessage('Love the lunch board');

    await controller.send();
    expect(controller.status, FeedbackStatus.queued);
  });

  test('a refusal keeps the draft and says why', () async {
    repository.refuseWith = const PermissionDeniedFailure();
    controller
      ..chooseKind(FeedbackKind.problem)
      ..setMessage('Broken');

    await controller.send();
    expect(controller.status, FeedbackStatus.editing);
    expect(controller.failure, isA<PermissionDeniedFailure>());
    expect(controller.kind, FeedbackKind.problem);
    expect(controller.canSend, isTrue);
  });

  test('starting another clears everything', () async {
    controller
      ..chooseKind(FeedbackKind.problem)
      ..chooseArea(FeedbackArea.calendar)
      ..setMessage('Broken')
      ..setMayContact(true);
    await controller.send();

    controller.startAnother();
    expect(controller.status, FeedbackStatus.editing);
    expect(controller.kind, isNull);
    expect(controller.area, isNull);
    expect(controller.mayContact, isFalse);
    expect(controller.canSend, isFalse);
  });
}
