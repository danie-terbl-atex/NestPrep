import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/state/invite_step_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_household.dart';
import '../../../support/fake_invite_sharer.dart';

/// Inviting as a step of setting up (household ADR-0003): a profile with its
/// role's grant, a code for it, and the share sheet — and closing the step,
/// whether anybody was invited or not.
void main() {
  late FakeHouseholdRepository repository;
  late FakeHouseholdDirectory directory;
  late FakeInviteSharer sharer;
  late InviteStepController controller;

  setUp(() {
    repository = FakeHouseholdRepository();
    directory = FakeHouseholdDirectory();
    sharer = FakeInviteSharer(appLink: Uri.parse('https://nestprep.test/get'));
    controller = InviteStepController(
      householdRepository: repository,
      householdDirectory: directory,
      inviteSharer: sharer,
      householdId: 'h1',
      householdName: 'The Parkers',
      coloursInUse: const [MemberColor.violet],
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('inviting makes the profile, then the code, then opens the share '
      'sheet', () async {
    final invited = await controller.invite(
      displayName: 'Thandi',
      role: MemberRole.helper,
    );

    expect(invited, isTrue);
    expect(repository.added.single.role, MemberRole.helper);
    expect(directory.invitesMade.single.memberId, 'm-new-1');
    expect(controller.sent.single.code, 'ABCD2345');
    expect(sharer.sent.single.text, contains('ABCD2345'));
    expect(
      sharer.sent.single.text,
      isNot(contains('https://')),
      reason: 'no link until the invite page is live (household ADR-0006)',
    );
  });

  test("a helper starts from the helper's grant, a parent from none", () async {
    await controller.invite(displayName: 'Thandi', role: MemberRole.helper);
    await controller.invite(displayName: 'Gogo', role: MemberRole.parent);

    expect(repository.added.first.access, AccessDefaults.helper);
    expect(repository.added.last.access, isNull);
  });

  test('a new face gets a colour nobody has yet', () async {
    await controller.invite(displayName: 'Thandi', role: MemberRole.helper);
    await controller.invite(displayName: 'Gogo', role: MemberRole.parent);

    final colours = repository.added.map((added) => added.color).toList();
    expect(colours, isNot(contains(MemberColor.violet)));
    expect(colours.toSet(), hasLength(2));
  });

  test('a refused profile is a banner, and no code is made for it', () async {
    repository.failWritesWith = const PermissionDeniedFailure();

    final invited = await controller.invite(
      displayName: 'Thandi',
      role: MemberRole.helper,
    );

    expect(invited, isFalse);
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    expect(directory.invitesMade, isEmpty);
    expect(controller.sent, isEmpty);
  });

  test(
    'a share sheet that will not open is said, and the code stays',
    () async {
      sharer.outcome = InviteShareOutcome.unavailable;
      await controller.invite(displayName: 'Thandi', role: MemberRole.helper);

      expect(controller.shareUnavailable, isTrue);
      expect(controller.sent, hasLength(1));
    },
  );

  test('a dismissed sheet is not a failure', () async {
    sharer.outcome = InviteShareOutcome.dismissed;
    await controller.invite(displayName: 'Thandi', role: MemberRole.helper);

    expect(controller.shareUnavailable, isFalse);
    expect(controller.actionFailure, isNull);
  });

  test('sharing again sends the same code again', () async {
    await controller.invite(displayName: 'Thandi', role: MemberRole.helper);
    await controller.shareAgain(controller.sent.single);

    expect(sharer.sent, hasLength(2));
    expect(sharer.sent.last.text, contains('ABCD2345'));
  });

  test('finishing closes the step', () async {
    expect(await controller.finish(), isTrue);
    expect(repository.setupStepsFinished, 1);
  });

  test('a second tap while one invite is in flight sends nothing', () async {
    directory.gate = Completer<void>();
    final first = controller.invite(
      displayName: 'Thandi',
      role: MemberRole.helper,
    );
    final second = await controller.invite(
      displayName: 'Thandi',
      role: MemberRole.helper,
    );
    directory.release();
    await first;

    expect(second, isFalse);
    expect(repository.added, hasLength(1));
  });
}
