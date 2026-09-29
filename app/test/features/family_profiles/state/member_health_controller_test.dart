import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/medication.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeFamilyProfileRepository repository;

  setUp(() => repository = FakeFamilyProfileRepository());
  tearDown(() => repository.close());

  MemberHealthController controllerFor({bool isVisible = true}) {
    final controller = MemberHealthController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.kidMemberId,
      isVisible: isVisible,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('a viewer who may not see medication never asks for it', () async {
    final controller = controllerFor(isVisible: false);
    await controller.retry();
    expect(repository.healthWatched, isEmpty);
    expect(controller.health, isA<AsyncLoading<MemberHealth>>());
  });

  test('a viewer who may, sees it live', () async {
    final controller = controllerFor();
    expect(repository.healthWatched, [Fixtures.kidMemberId]);
    repository.emitHealth(
      const MemberHealth(
        id: Fixtures.kidMemberId,
        medications: {'a': FamilyFixtures.inhaler},
      ),
    );
    await pumpEventQueue();
    final health = (controller.health as AsyncData<MemberHealth>).value;
    expect(health.medications['a'], FamilyFixtures.inhaler);
  });

  test('a refused read is a failure with a retry', () async {
    final controller = controllerFor();
    repository.failHealthWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(controller.health, isA<AsyncFailure<MemberHealth>>());

    await controller.retry();
    expect(controller.health, isA<AsyncLoading<MemberHealth>>());
    expect(repository.healthWatched, hasLength(2));
  });

  test('an error that is not ours is still a failure', () async {
    final controller = controllerFor();
    repository.failHealthWith(StateError('boom'));
    await pumpEventQueue();
    expect(
      (controller.health as AsyncFailure<MemberHealth>).failure,
      isA<UnknownFailure>(),
    );
  });

  test(
    'a medicine is saved tidied: trimmed, blanks absent, times in order',
    () async {
      final controller = controllerFor();
      await controller.saveMedication(
        const Medication(
          name: ' Inhaler ',
          dose: '  ',
          note: ' With food ',
          times: [1200, 420, 1200],
        ),
      );
      final arguments = repository.writes.single.$2;
      expect(arguments['medicationId'], isNull, reason: 'a new one');
      expect(
        arguments['medication'],
        const Medication(
          name: 'Inhaler',
          note: 'With food',
          times: [420, 1200],
        ),
      );
    },
  );

  test('editing one names it, and a nameless medicine is not saved', () async {
    final controller = controllerFor();
    await controller.saveMedication(FamilyFixtures.inhaler, medicationId: 'a');
    await controller.saveMedication(const Medication(name: '  '));
    expect(repository.writes.single.$2['medicationId'], 'a');
  });

  test('removing one, and a refusal becomes a banner', () async {
    final controller = controllerFor();
    await controller.removeMedication('a');
    final (method, arguments) = repository.writes.single;
    expect(method, 'removeMedication');
    expect(arguments, {'memberId': Fixtures.kidMemberId, 'medicationId': 'a'});

    repository.failWritesWith = const PermissionDeniedFailure();
    await controller.removeMedication('a');
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
  });
}
