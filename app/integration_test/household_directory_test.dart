import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import 'household_fixture.dart';

/// The callable directory against the real Functions emulator (ADR-0010).
///
/// `BE-04` is the reason this matters. Three different refusals share the gRPC
/// code `already-exists`, so the code alone cannot choose copy — every refusal
/// carries a `reason` in the error's `details`, and the client maps that string
/// to a `HouseholdProblem` by name.
///
/// `test/features/household/data/refusal_contract_test.dart` already reads
/// `functions/src/household/errors.ts` from disk and checks the names line up on
/// both sides. What it cannot check is the **mechanism**: that `details` arrives
/// at a Dart client as a map with `reason` in it at all. If that ever stopped
/// being true — a Functions SDK change, a different transport — every refusal
/// would fall through to `unrecognised` and every one of them would show the
/// same general apology. Silently, because the names would still match.
///
/// So these trigger real refusals through real callables and assert the specific
/// problem, which is the only way that mechanism gets tested.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestHousehold home;

  setUpAll(() async => home = await signInAndCreateAHousehold());

  setUp(() async => home = await home.freshHousehold());

  tearDownAll(() async => home.signOut());

  /// The `HouseholdProblem` a call refuses with, or a failure for the test to
  /// complain about.
  Future<HouseholdProblem> problemFrom(Future<void> Function() call) async {
    try {
      await call();
      fail('the call was expected to be refused and was not');
    } on HouseholdFailure catch (failure) {
      return failure.problem;
    }
  }

  group('a refusal arrives with its reason, not just a gRPC code', () {
    test('an invite code that is not one is inviteNotFound', () async {
      // `not-found` on the wire. If `details` were lost this would still be a
      // failure, just the wrong one — which is the whole point of asserting the
      // problem rather than that it threw.
      expect(
        await problemFrom(() => home.directory.redeemInvite('ZZZZZZ')),
        HouseholdProblem.inviteNotFound,
      );
    });

    test(
      'removing yourself is cannotRemoveSelf, not a permission error',
      () async {
        // `failed-precondition`, and the copy has to say "leave instead" rather
        // than "you are not allowed" — two very different sentences from one call.
        expect(
          await problemFrom(
            () => home.directory.removeMember(
              householdId: home.id,
              memberId: home.memberId,
            ),
          ),
          HouseholdProblem.cannotRemoveSelf,
        );
      },
    );

    test('leaving as the only admin is lastAdmin', () async {
      // The household would be left with nobody who can manage it. Also
      // `failed-precondition`, so this and the one above are only told apart by
      // the reason in the details.
      expect(
        await problemFrom(() => home.directory.leaveHousehold(home.id)),
        HouseholdProblem.lastAdmin,
      );
    });

    test('a member id that does not exist is memberNotFound', () async {
      expect(
        await problemFrom(
          () => home.directory.removeMember(
            householdId: home.id,
            memberId: 'no-such-member',
          ),
        ),
        HouseholdProblem.memberNotFound,
      );
    });

    test('a household that does not exist is householdNotFound', () async {
      // Measured, not assumed: `leaveHousehold` looks the household up *before*
      // checking membership, so a stranger is told it does not exist rather than
      // that they are not in it. Worth writing down — it means the refusal
      // distinguishes "no such household" from "not yours" to somebody who is
      // neither, which is bounded only by household ids being unguessable
      // 20-character Firestore ids. If that ever stops being true, the order of
      // these two checks is the thing to change.
      expect(
        await problemFrom(
          () => home.directory.leaveHousehold('someone-elses-household'),
        ),
        HouseholdProblem.householdNotFound,
      );
    });

    test('two refusals sharing failed-precondition are still told apart', () async {
      // Stated as its own case because it is the property `BE-04` exists for,
      // and it would pass vacuously if either arm above regressed to a generic
      // failure.
      final removingSelf = await problemFrom(
        () => home.directory.removeMember(
          householdId: home.id,
          memberId: home.memberId,
        ),
      );
      final leavingAsLastAdmin = await problemFrom(
        () => home.directory.leaveHousehold(home.id),
      );

      expect(removingSelf, isNot(leavingAsLastAdmin));
      expect(removingSelf, HouseholdProblem.cannotRemoveSelf);
      expect(leavingAsLastAdmin, HouseholdProblem.lastAdmin);
    });

    test('nothing falls through to unrecognised', () async {
      // `unrecognised` means the app met a reason it has no copy for — a Function
      // newer than the build. Against this emulator, running this repo's own
      // Functions, it must never happen.
      final problems = [
        await problemFrom(() => home.directory.redeemInvite('ZZZZZZ')),
        await problemFrom(() => home.directory.leaveHousehold(home.id)),
        await problemFrom(
          () => home.directory.removeMember(
            householdId: home.id,
            memberId: 'no-such-member',
          ),
        ),
      ];

      expect(problems, isNot(contains(HouseholdProblem.unrecognised)));
      expect(problems, isNot(contains(HouseholdProblem.badRequest)));
    });
  });

  group('the calls that succeed', () {
    test('an invite is created for an unclaimed profile', () async {
      // A second profile first: the admin's own is claimed, and an invite is for
      // a profile nobody has taken.
      await home.households.addMember(
        householdId: home.id,
        displayName: 'Ada',
        color: MemberColor.teal,
        role: MemberRole.member,
      );
      final profiles = await home.households.watchMembers(home.id).first;
      final unclaimed = profiles.firstWhere(
        (profile) => profile.claimedBy == null,
      );

      final invite = await home.directory.createInvite(
        householdId: home.id,
        memberId: unclaimed.id,
      );

      expect(invite.code, isNotEmpty);
      expect(
        invite.code,
        invite.code.toUpperCase(),
        reason: 'codes are upper-cased so they can be read aloud',
      );
      expect(invite.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('redeeming your own household is alreadyInHousehold', () async {
      // The refusal that needs a real invite to reach, and the third of the
      // three that share `already-exists`.
      await home.households.addMember(
        householdId: home.id,
        displayName: 'Ada',
        color: MemberColor.teal,
        role: MemberRole.member,
      );
      final profiles = await home.households.watchMembers(home.id).first;
      final unclaimed = profiles.firstWhere(
        (profile) => profile.claimedBy == null,
      );
      final invite = await home.directory.createInvite(
        householdId: home.id,
        memberId: unclaimed.id,
      );

      expect(
        await problemFrom(() => home.directory.redeemInvite(invite.code)),
        HouseholdProblem.alreadyInHousehold,
      );
    });

    test('an admin can change a member role', () async {
      await home.households.addMember(
        householdId: home.id,
        displayName: 'Ada',
        color: MemberColor.teal,
        role: MemberRole.member,
      );
      final profiles = await home.households.watchMembers(home.id).first;
      final other = profiles.firstWhere((profile) => profile.claimedBy == null);

      await home.directory.setMemberRole(
        householdId: home.id,
        memberId: other.id,
        role: MemberRole.helper,
      );

      // A Function made this change, not this client, so the local cache does
      // not have it yet and `watchMembers(...).first` would hand back the stale
      // snapshot — which is exactly how this test failed the first time. Wait
      // for the listener to be told instead.
      final changed = await home.households
          .watchMembers(home.id)
          .map(
            (profiles) =>
                profiles.firstWhere((profile) => profile.id == other.id).role,
          )
          .firstWhere((role) => role == MemberRole.helper)
          .timeout(const Duration(seconds: 10));

      expect(changed, MemberRole.helper);
    });
  });
}
