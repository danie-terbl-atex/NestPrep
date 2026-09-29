import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/features/referrals/model/household_referral.dart';
import 'package:nestprep/features/referrals/model/referral_overview.dart';
import 'package:nestprep/features/referrals/state/referral_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_invite_sharer.dart';
import '../../../support/fake_referrals.dart';

/// Give a month, get a month for one household (subscriptions ADR-0002): the
/// code made once by the server, shared the way invites are, and another
/// family's code entered with its refusal kept for the field.
void main() {
  final now = DateTime.utc(2026, 10, 3, 9);
  const withCode = HouseholdReferral(code: 'ABCD2345', yearlyRewardCap: 6);

  late FakeReferralRepository repository;
  late FakeReferralDirectory directory;
  late FakeInviteSharer sharer;

  ReferralController controllerOver({
    HouseholdReferral? referral = withCode,
    Uri? appLink,
  }) {
    repository = FakeReferralRepository(
      referral: referral,
      lines: const [],
      grants: const [],
    );
    directory = FakeReferralDirectory();
    sharer = FakeInviteSharer(appLink: appLink);
    final controller = ReferralController(
      referralRepository: repository,
      referralDirectory: directory,
      inviteSharer: sharer,
      householdId: 'h1',
      now: () => now,
    );
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });
    return controller;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('is loading until all three reads have answered', () async {
    repository = FakeReferralRepository();
    final controller = ReferralController(
      referralRepository: repository,
      referralDirectory: FakeReferralDirectory(),
      inviteSharer: FakeInviteSharer(),
      householdId: 'h1',
    );
    addTearDown(controller.dispose);
    repository.emitReferral(withCode);
    await settle();
    expect(controller.overview, isA<AsyncLoading<ReferralOverview>>());
    repository
      ..emitLines(const [])
      ..emitGrants(const []);
    await settle();
    expect(controller.overview, isA<AsyncData<ReferralOverview>>());
  });

  test('asks the server for a code once when the household has none', () async {
    final controller = controllerOver(referral: HouseholdReferral.none);
    await settle();
    expect(directory.ensured, ['h1']);
    repository.emitReferral(HouseholdReferral.none);
    await settle();
    expect(directory.ensured, ['h1'], reason: 'one code, however often');
    expect(controller.codeFailure, isNull);
  });

  test(
    'keeps a failure to make the code, and tries again when asked',
    () async {
      repository = FakeReferralRepository(
        referral: HouseholdReferral.none,
        lines: const [],
        grants: const [],
      );
      directory = FakeReferralDirectory()
        ..failEnsureWith = const UnavailableFailure();
      final controller = ReferralController(
        referralRepository: repository,
        referralDirectory: directory,
        inviteSharer: FakeInviteSharer(),
        householdId: 'h1',
      );
      addTearDown(controller.dispose);
      await settle();
      expect(controller.codeFailure, isA<UnavailableFailure>());

      directory.failEnsureWith = null;
      await controller.retryCode();
      expect(controller.codeFailure, isNull);
      expect(directory.ensured, ['h1', 'h1']);
    },
  );

  test(
    'shares the code with the link that carries it, when one is set',
    () async {
      final controller = controllerOver(
        appLink: Uri.parse('https://nestprep.app/get?from=app'),
      );
      await settle();
      await controller.share();
      final [message] = sharer.sent;
      expect(message.text, contains('ABCD2345'));
      expect(
        message.text,
        contains('https://nestprep.app/get?from=app&referral=ABCD2345'),
      );
      expect(controller.shareUnavailable, isFalse);
    },
  );

  test('says so when the share sheet will not open', () async {
    final controller = controllerOver();
    await settle();
    sharer.outcome = InviteShareOutcome.unavailable;
    await controller.share();
    expect(controller.shareUnavailable, isTrue);
  });

  test(
    'enters another family’s code, trimmed, and answers that it was taken',
    () async {
      final controller = controllerOver();
      await settle();
      expect(await controller.redeem(' WXYZ2345 '), isTrue);
      expect(directory.redeemed, [(householdId: 'h1', code: 'WXYZ2345')]);
      expect(controller.redeemFailure, isNull);
      expect(controller.isRedeeming, isFalse);
    },
  );

  test(
    'keeps a refused code for the field, until the person types again',
    () async {
      final controller = controllerOver();
      await settle();
      directory.failRedeemWith = const ReferralFailure(
        ReferralProblem.ownReferralCode,
      );
      expect(await controller.redeem('ABCD2345'), isFalse);
      expect(
        controller.redeemFailure,
        const ReferralFailure(ReferralProblem.ownReferralCode),
      );
      controller.clearRedeemFailure();
      expect(controller.redeemFailure, isNull);
    },
  );

  test(
    'fails the whole screen on a read it cannot make, and reads again on retry',
    () async {
      final controller = controllerOver();
      await settle();
      repository.failHistory(const PermissionDeniedFailure());
      await settle();
      expect(controller.overview, isA<AsyncFailure<ReferralOverview>>());
      controller.retry();
      await settle();
      expect(controller.overview, isA<AsyncData<ReferralOverview>>());
    },
  );
}
