import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_draft.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_roster.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeFamilyProfileRepository repository;
  late FamilyController controller;

  setUp(() {
    repository = FakeFamilyProfileRepository();
    controller = FamilyController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      household: Fixtures.view(),
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  FamilyRoster roster() => (controller.roster as AsyncData<FamilyRoster>).value;

  Future<void> loaded() async {
    repository.emitProfiles([FamilyFixtures.kid]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    await pumpEventQueue();
  }

  group('reading', () {
    test('waits for both reads, so a profile never shows without its school '
        'rule', () async {
      repository.emitProfiles([FamilyFixtures.kid]);
      await pumpEventQueue();
      expect(controller.roster, isA<AsyncLoading<FamilyRoster>>());

      repository.emitSchools([FamilyFixtures.oakwood]);
      await pumpEventQueue();
      final kid = roster().entryFor(Fixtures.kidMemberId)!;
      expect(kid.foodRules.isNutFree, isTrue);
    });

    test(
      'a refused read is a failure the screen can say, not a crash',
      () async {
        repository.failProfilesWith(const PermissionDeniedFailure());
        await pumpEventQueue();
        expect(
          (controller.roster as AsyncFailure<FamilyRoster>).failure,
          isA<PermissionDeniedFailure>(),
        );
      },
    );

    test(
      'an error that is not ours is still a failure, never thrown',
      () async {
        repository.failProfilesWith(StateError('boom'));
        await pumpEventQueue();
        expect(
          (controller.roster as AsyncFailure<FamilyRoster>).failure,
          isA<UnknownFailure>(),
        );
      },
    );

    test('retry goes back to loading and listens again', () async {
      repository.failProfilesWith(const UnavailableFailure());
      await pumpEventQueue();
      await controller.retry();
      expect(controller.roster, isA<AsyncLoading<FamilyRoster>>());
      await loaded();
      expect(roster().childCount, 1);
    });

    test(
      'follows the household: a new member appears without a new read',
      () async {
        await loaded();
        const newcomer = Member(
          id: 'm-new',
          displayName: 'Newborn',
          color: MemberColor.sky,
          roleName: 'member',
        );
        controller.followHousehold(
          Fixtures.view(
            members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid, newcomer],
          ),
        );
        expect(roster().entryFor('m-new'), isNotNull);
      },
    );

    test('follows a change of role into what the viewer may do', () async {
      await loaded();
      expect(controller.access.canEdit(Fixtures.kidMemberId), isTrue);
      controller.followHousehold(Fixtures.view(viewerUid: Fixtures.thandiUid));
      expect(controller.access.canEdit(Fixtures.kidMemberId), isFalse);
    });

    test('an unchanged household is not a change', () async {
      await loaded();
      var notified = 0;
      controller.addListener(() => notified++);
      controller.followHousehold(Fixtures.view());
      expect(notified, 0);
    });
  });

  group('writing', () {
    test('food is saved trimmed, once each, as the sheet showed it', () async {
      await controller.edit.saveFood(
        Fixtures.kidMemberId,
        likes: [' Pasta ', 'pasta', '', 'Apples'],
        dislikes: ['Mushrooms'],
        diet: {DietaryFlag.halal},
      );
      final (method, arguments) = repository.writes.single;
      expect(method, 'saveFood');
      expect(arguments['likes'], ['Pasta', 'Apples']);
      expect(arguments['diet'], {DietaryFlag.halal});
    });

    test('an allergy change carries the one it replaces', () async {
      await loaded();
      final peanut = roster()
          .entryFor(Fixtures.kidMemberId)!
          .foodRules
          .allergies
          .first;
      const sesame = AllergyDraft.known(
        allergen: Allergen.sesame,
        severity: AllergySeverity.severe,
      );
      await controller.edit.saveAllergy(
        Fixtures.kidMemberId,
        sesame,
        replacing: peanut,
      );
      final arguments = repository.writes.single.$2;
      expect(arguments['draft'], sesame);
      expect(arguments['replacing'], peanut);
    });

    test('a blank grade or size is no grade, stored as null', () async {
      await controller.edit.saveSchooling(
        Fixtures.kidMemberId,
        schoolId: 'oakwood',
        grade: '  ',
      );
      await controller.edit.saveSizes(
        Fixtures.kidMemberId,
        clothingSize: ' 7–8 ',
        shoeSize: '',
      );
      expect(repository.writes[0].$2['grade'], isNull);
      expect(repository.writes[1].$2['clothingSize'], '7–8');
      expect(repository.writes[1].$2['shoeSize'], isNull);
    });

    test('marking somebody a child is one write', () async {
      await controller.edit.setIsChild(Fixtures.kidMemberId, isChild: false);
      final (method, arguments) = repository.writes.single;
      expect(method, 'setIsChild');
      expect(arguments, {'memberId': Fixtures.kidMemberId, 'isChild': false});
    });

    test(
      'adding a school answers with its id so a sheet can choose it',
      () async {
        final id = await controller.edit.addSchool(
          name: ' Oakwood ',
          nutFree: true,
        );
        expect(id, isNotNull);
        expect(repository.writes.single.$2, {
          'name': 'Oakwood',
          'nutFree': true,
        });
      },
    );

    test('a school with no name is not a school', () async {
      expect(
        await controller.edit.addSchool(name: '  ', nutFree: false),
        isNull,
      );
      await controller.edit.updateSchool('s', name: '', nutFree: true);
      expect(repository.writes, isEmpty);
    });

    test('updates and deletes a school', () async {
      await controller.edit.updateSchool('s', name: 'New', nutFree: false);
      await controller.edit.deleteSchool('s');
      expect(repository.writes.map((write) => write.$1), [
        'updateSchool',
        'deleteSchool',
      ]);
    });

    test(
      'a refused write becomes a banner, and the next one clears it',
      () async {
        repository.failWritesWith = const PermissionDeniedFailure();
        await controller.edit.setIsChild(Fixtures.kidMemberId, isChild: true);
        expect(controller.actionFailure, isA<PermissionDeniedFailure>());

        await controller.edit.setIsChild(Fixtures.kidMemberId, isChild: true);
        expect(controller.actionFailure, isNull);
      },
    );

    test('a refused school add answers with no id', () async {
      repository.failWritesWith = const PermissionDeniedFailure();
      expect(
        await controller.edit.addSchool(name: 'Oakwood', nutFree: true),
        isNull,
      );
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    });

    test('removing an allergy names it', () async {
      await loaded();
      final kiwi = roster()
          .entryFor(Fixtures.kidMemberId)!
          .foodRules
          .allergies
          .firstWhere((allergy) => allergy.otherId == 'k1');
      await controller.edit.removeAllergy(Fixtures.kidMemberId, kiwi);
      expect(repository.writes.single.$2['allergy'], kiwi);
    });
  });
}
