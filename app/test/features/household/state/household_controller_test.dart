import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';

/// The household screen's controller: two live reads joined into one view, and
/// the admin actions the screen offers.
///
/// This is where a role change decides whether it is a direct write or a
/// callable, and where being removed from a household has to look like
/// something rather than a crash. None of it had a test.
void main() {
  late FakeHouseholdRepository repository;
  late FakeHouseholdDirectory directory;
  late HouseholdController controller;

  setUp(() {
    repository = FakeHouseholdRepository();
    directory = FakeHouseholdDirectory();
    controller = HouseholdController(
      householdRepository: repository,
      householdDirectory: directory,
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  /// Both reads arrive, which is when the screen has something to draw.
  Future<void> settle({List<Member>? members}) async {
    repository.emitHousehold(Fixtures.household());
    repository.emitMembers(
      members ?? [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
    await pumpEventQueue();
  }

  group('joining the two reads', () {
    test('holds on loading until the members have arrived too', () async {
      repository.emitHousehold(Fixtures.household());
      await pumpEventQueue();
      expect(
        controller.view,
        isA<AsyncLoading<Object?>>(),
        reason: 'a household with no member list is half a screen',
      );
    });

    test('publishes the view once both are in', () async {
      await settle();
      final view = controller.view;
      expect(view, isA<AsyncData<HouseholdView>>());
      final value = (view as AsyncData<HouseholdView>).value;
      expect(value.members, hasLength(3));
      expect(value.household.name, 'The Parkers');
      expect(value.viewerMember?.id, Fixtures.samMemberId);
    });

    test(
      'a household that goes away reads as not found, not as a crash',
      () async {
        await settle();
        repository.emitHousehold(null);
        await pumpEventQueue();

        expect(controller.view, isA<AsyncFailure<Object?>>());
        expect(
          (controller.view as AsyncFailure).failure,
          isA<NotFoundFailure>(),
          reason: 'being removed is what this looks like from the member side',
        );
      },
    );

    test('a stream error becomes a failure the screen can retry', () async {
      repository.failHouseholdWith(const UnavailableFailure());
      await pumpEventQueue();
      expect(controller.view, isA<AsyncFailure<Object?>>());

      await controller.retry();
      expect(controller.view, isA<AsyncLoading<Object?>>());
      await settle();
      expect(controller.view, isA<AsyncData<Object?>>());
    });
  });

  group('changing a role', () {
    test(
      "an unclaimed profile's role is a direct write and nothing else",
      () async {
        await settle();

        await controller.updateMember(
          memberId: Fixtures.kidMemberId,
          displayName: 'Kid Parker',
          color: MemberColor.sky,
          role: MemberRole.helper,
        );

        expect(repository.updated.single.role, MemberRole.helper);
        expect(
          directory.rolesSet,
          isEmpty,
          reason: 'nobody has claimed it, so no uid→role map to keep in step',
        );
      },
    );

    test('a claimed member keeps the old role on the document and moves through the callable', () async {
      await settle();

      await controller.updateMember(
        memberId: Fixtures.thandiMemberId,
        displayName: 'Thandi Helper',
        color: MemberColor.mint,
        role: MemberRole.admin,
      );

      expect(
        repository.updated.single.role,
        MemberRole.helper,
        reason:
            'the direct write must not move a claimed role — the rules '
            'refuse it, and the household map would fall out of step',
      );
      expect(directory.rolesSet.single.memberId, Fixtures.thandiMemberId);
      expect(directory.rolesSet.single.role, MemberRole.admin);
    });

    test('renaming a claimed member without touching their role stays a direct write', () async {
      await settle();

      await controller.updateMember(
        memberId: Fixtures.thandiMemberId,
        displayName: 'Thandi P',
        color: MemberColor.mint,
        role: MemberRole.helper,
      );

      expect(repository.updated.single.displayName, 'Thandi P');
      expect(directory.rolesSet, isEmpty);
    });
  });

  group('a grant follows the role (household ADR-0003)', () {
    test('a new helper is written with the helper defaults', () async {
      await settle();
      await controller.addMember(
        displayName: 'Grace',
        color: MemberColor.teal,
        role: MemberRole.helper,
      );
      expect(repository.added.single.access, AccessDefaults.helper);
    });

    test('a new parent is written with no grant — family needs none', () async {
      await settle();
      await controller.addMember(
        displayName: 'Gogo',
        color: MemberColor.teal,
        role: MemberRole.parent,
      );
      expect(repository.added.single.access, isNull);
    });

    test(
      'an unclaimed profile made a carer starts from the carer grant',
      () async {
        await settle();
        await controller.updateMember(
          memberId: Fixtures.kidMemberId,
          displayName: 'Kid Parker',
          color: MemberColor.sky,
          role: MemberRole.carer,
        );
        expect(repository.updated.single.access, AccessDefaults.carer);
      },
    );

    test('a rename that leaves the role alone sends no grant', () async {
      await settle();
      await controller.updateMember(
        memberId: Fixtures.kidMemberId,
        displayName: 'Kiddo',
        color: MemberColor.sky,
        role: Fixtures.kid.role,
      );
      expect(
        repository.updated.single.access,
        isNull,
        reason: 'a parent adjusted it; renaming must not reset it',
      );
    });
  });

  group('actions', () {
    test('an invite is kept for the sheet, and can be dismissed', () async {
      await settle();
      expect(controller.lastInvite, isNull);

      await controller.createInvite(Fixtures.kidMemberId);
      expect(controller.lastInvite?.code, 'ABCD2345');
      expect(directory.invitesMade.single.memberId, Fixtures.kidMemberId);

      controller.dismissInvite();
      expect(controller.lastInvite, isNull);
    });

    test('a refusal becomes copy on the screen, never an exception', () async {
      await settle();
      directory.failWith = const PermissionDeniedFailure();

      await controller.removeMember(Fixtures.kidMemberId);

      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      expect(controller.isBusy, isFalse, reason: 'the spinner has to stop');
      controller.dismissActionFailure();
      expect(controller.actionFailure, isNull);
    });

    test(
      'a second action while one is in flight is refused, not queued',
      () async {
        await settle();
        directory.gate = Completer<void>();

        final first = controller.leaveHousehold();
        await pumpEventQueue();
        expect(controller.isBusy, isTrue);

        final second = await controller.leaveHousehold();
        expect(second, isFalse, reason: 'double-tap must not leave twice');

        directory.release();
        await first;
        expect(directory.left, hasLength(1));
        expect(controller.isBusy, isFalse);
      },
    );

    test(
      'adding a profile and renaming the household go straight to Firestore',
      () async {
        await settle();

        await controller.addMember(
          displayName: 'Gogo',
          color: MemberColor.sky,
          role: MemberRole.parent,
        );
        await controller.renameHousehold(
          name: 'The Parker-Dlaminis',
          timeZone: 'Africa/Johannesburg',
        );

        expect(repository.added.single.displayName, 'Gogo');
        expect(repository.renamed.single.name, 'The Parker-Dlaminis');
        expect(
          directory.created,
          isEmpty,
          reason: 'neither of these changes who is in the household',
        );
      },
    );
  });
}
