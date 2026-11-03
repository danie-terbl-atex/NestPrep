import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher.dart';
import 'package:nestprep/features/subscriptions/state/voucher_email_controller.dart';
import 'package:nestprep/features/subscriptions/ui/premium_voucher_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/premium_voucher_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/fake_premium_vouchers.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// "Ordered with a different email?" (subscriptions ADR-0003): an email, a
/// 6-digit code to it, and once it is proven the Premium sent to it is asked
/// for again — with every refusal, the resend and its cooldown.
void main() {
  late SubscriptionHarness premium;

  const frame = FakePremiumVoucherDirectory.frame;
  const masked = 'p***@example.com';

  Future<void> openEmail(
    WidgetTester tester, {
    List<PremiumVoucher> waiting = const [],
    bool startWithEmail = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    premium = SubscriptionHarness();
    premium.vouchers.waiting = [...waiting];
    final households = FakeHouseholdRepository();
    addTearDown(households.close);
    premium.inbox.attach(Fixtures.samUid);
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showPremiumVoucherSheet(
              context,
              startWithEmail: startWithEmail,
            ),
            child: const Text('open'),
          ),
        ),
      ),
      providers: [
        ...premium.providers,
        Provider<HouseholdRepository>.value(value: households),
      ],
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pump();
    await tester.pump();
  }

  Future<void> sendTo(WidgetTester tester, String email) async {
    await tester.enterText(find.byKey(const ValueKey('voucher-email')), email);
    await tapKey(tester, 'voucher-send-code');
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const ValueKey('voucher-code')), code);
    await tapKey(tester, 'voucher-verify');
  }

  Future<void> waitOutCooldown(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 31));
  }

  Finder resend() => find.byKey(const ValueKey('voucher-resend'));

  bool resendEnabled(WidgetTester tester) =>
      tester.widget<NestButton>(resend()).onPressed != null;

  testWidgets('asks for an email, and refuses one that is not', (tester) async {
    await openEmail(tester);
    expect(find.text(PremiumVoucherCopy.differentEmail), findsOneWidget);

    await sendTo(tester, 'not an email');
    expect(find.text(PremiumVoucherCopy.badEmail), findsOneWidget);
    expect(premium.vouchers.sentTo, isEmpty);
  });

  testWidgets('sends a code, then lets another go only after the cooldown', (
    tester,
  ) async {
    await openEmail(tester);
    await sendTo(tester, '  Sam.Parent@Example.com ');

    expect(premium.vouchers.sentTo, ['Sam.Parent@Example.com']);
    expect(find.text(PremiumVoucherCopy.codeSent(masked)), findsOneWidget);
    expect(resendEnabled(tester), isFalse);
    expect(find.text(PremiumVoucherCopy.newCodeIn(30)), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    expect(find.text(PremiumVoucherCopy.newCodeIn(20)), findsOneWidget);

    await waitOutCooldown(tester);
    expect(resendEnabled(tester), isTrue);
    await tapKey(tester, 'voucher-resend');
    expect(premium.vouchers.sentTo, hasLength(2));
    expect(resendEnabled(tester), isFalse);
    await waitOutCooldown(tester);
  });

  testWidgets('wants all six digits before it asks', (tester) async {
    await openEmail(tester);
    await sendTo(tester, 'sam@example.com');
    await enterCode(tester, '123');
    expect(find.text(PremiumVoucherCopy.codeIncomplete), findsOneWidget);
    expect(premium.vouchers.verified, isEmpty);
    await waitOutCooldown(tester);
  });

  testWidgets('a proven email finds its Premium and offers to add it', (
    tester,
  ) async {
    await openEmail(tester);
    premium.vouchers.provenByEmail = [frame];
    await sendTo(tester, 'sam@example.com');
    await enterCode(tester, '123456');
    await tester.pumpAndSettle();

    expect(premium.vouchers.verified, [
      (email: 'sam@example.com', code: '123456'),
    ]);
    expect(find.text(PremiumVoucherCopy.confirmed(masked)), findsOneWidget);
    expect(
      find.text('3 months of Premium from your frame order'),
      findsOneWidget,
    );
    await tapKey(tester, 'claim-${frame.voucherId}');
    await tester.pumpAndSettle();
    expect(find.text(PremiumVoucherCopy.added('The Parkers')), findsOneWidget);
  });

  testWidgets('a proven email with nothing waiting says so', (tester) async {
    await openEmail(tester);
    await sendTo(tester, 'sam@example.com');
    final listedBefore = premium.vouchers.listed;
    await enterCode(tester, '654321');
    await tester.pumpAndSettle();

    expect(premium.vouchers.listed, listedBefore + 1);
    expect(
      find.text(PremiumVoucherCopy.nothingWaitingFor(masked)),
      findsOneWidget,
    );
    expect(find.text(PremiumVoucherCopy.done), findsOneWidget);
  });

  testWidgets('a lookup that fails after the email is proven says so, with '
      'a retry, and never that nothing is waiting', (tester) async {
    await openEmail(tester);
    await sendTo(tester, 'sam@example.com');
    premium.vouchers.failListWith = const UnavailableFailure();
    await enterCode(tester, '654321');
    await tester.pumpAndSettle();

    final failed = find.byKey(const ValueKey('voucher-lookup-failed'));
    expect(failed, findsOneWidget);
    expect(tester.widget<NestBanner>(failed).tone, NestBannerTone.danger);
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(
      find.text(PremiumVoucherCopy.nothingWaitingFor(masked)),
      findsNothing,
    );

    premium.vouchers
      ..failListWith = null
      ..waiting = [frame];
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(failed, findsNothing);
    expect(find.text(PremiumVoucherCopy.confirmed(masked)), findsOneWidget);
    expect(
      find.text('3 months of Premium from your frame order'),
      findsOneWidget,
    );
  });

  testWidgets('a wrong code is said on the field, and typing clears it', (
    tester,
  ) async {
    await openEmail(tester);
    await sendTo(tester, 'sam@example.com');
    const wrong = PremiumVoucherFailure(PremiumVoucherProblem.emailCodeWrong);
    premium.vouchers.failVerifyWith = wrong;
    await enterCode(tester, '111111');
    expect(find.text(AppCopy.failure(wrong)), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('voucher-code')), '11111');
    await tester.pump();
    expect(find.text(AppCopy.failure(wrong)), findsNothing);
    await waitOutCooldown(tester);
  });

  for (final problem in [
    PremiumVoucherProblem.emailCodeExpired,
    PremiumVoucherProblem.emailCodeTooManyTries,
  ]) {
    testWidgets('${problem.name}: says so, and a new code can be sent', (
      tester,
    ) async {
      await openEmail(tester);
      await sendTo(tester, 'sam@example.com');
      final refusal = PremiumVoucherFailure(problem);
      premium.vouchers.failVerifyWith = refusal;
      await enterCode(tester, '222222');
      expect(find.text(AppCopy.failure(refusal)), findsOneWidget);

      await waitOutCooldown(tester);
      premium.vouchers.failVerifyWith = null;
      await tapKey(tester, 'voucher-resend');
      expect(premium.vouchers.sentTo, hasLength(2));
      expect(find.text(AppCopy.failure(refusal)), findsNothing);
      await waitOutCooldown(tester);
    });
  }

  testWidgets('tooManyCodes: says so and stops offering another', (
    tester,
  ) async {
    await openEmail(tester);
    await sendTo(tester, 'sam@example.com');
    await waitOutCooldown(tester);
    const refusal = PremiumVoucherFailure(PremiumVoucherProblem.tooManyCodes);
    premium.vouchers.failSendWith = refusal;
    await tapKey(tester, 'voucher-resend');

    expect(find.text(AppCopy.failure(refusal)), findsOneWidget);
    expect(resendEnabled(tester), isFalse);
  });

  testWidgets('tooManyCodes on the first send stays on the email', (
    tester,
  ) async {
    await openEmail(tester);
    const refusal = PremiumVoucherFailure(PremiumVoucherProblem.tooManyCodes);
    premium.vouchers.failSendWith = refusal;
    await sendTo(tester, 'sam@example.com');
    expect(find.text(AppCopy.failure(refusal)), findsOneWidget);
    expect(find.byKey(const ValueKey('voucher-email')), findsOneWidget);
  });

  testWidgets('emailAlreadyVerified: looks again for what it was sent', (
    tester,
  ) async {
    await openEmail(tester);
    premium.vouchers.failSendWith = const PremiumVoucherFailure(
      PremiumVoucherProblem.emailAlreadyVerified,
    );
    premium.vouchers.waiting = [frame];
    final listedBefore = premium.vouchers.listed;
    await sendTo(tester, 'sam@example.com');
    await tester.pumpAndSettle();

    expect(premium.vouchers.listed, listedBefore + 1);
    expect(
      find.text('3 months of Premium from your frame order'),
      findsOneWidget,
    );
    expect(
      find.text(PremiumVoucherCopy.confirmed('s***@example.com')),
      findsOneWidget,
    );
    expect(find.textContaining('sam@example.com'), findsNothing);
  });

  test('masks an email the way the server does', () {
    expect(
      VoucherEmailController.masked('  Sam.Parent@Example.COM '),
      's***@example.com',
    );
    expect(VoucherEmailController.masked('a@b.co'), 'a***@b.co');
  });

  testWidgets('a refusal it cannot place is still said', (tester) async {
    await openEmail(tester);
    premium.vouchers.failSendWith = const UnavailableFailure();
    await sendTo(tester, 'sam@example.com');
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
  });

  testWidgets('a different email can be typed after a code was sent', (
    tester,
  ) async {
    await openEmail(tester);
    await sendTo(tester, 'sam@example.com');
    await tester.ensureVisible(find.text(PremiumVoucherCopy.useAnotherEmail));
    await tester.tap(find.text(PremiumVoucherCopy.useAnotherEmail));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('voucher-email')), findsOneWidget);
  });

  testWidgets('the claim sheet opens it, and it never mentions the web page', (
    tester,
  ) async {
    await openEmail(tester, waiting: [frame], startWithEmail: false);
    await tapKey(tester, 'voucher-different-email');
    await tester.pumpAndSettle();
    expect(find.text(PremiumVoucherCopy.differentEmailBody), findsOneWidget);
    expect(find.textContaining('redeem'), findsNothing);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await openEmail(tester, brightness: Brightness.dark, textScale: 2);
    await sendTo(tester, 'not an email');
    await sendTo(tester, 'sam@example.com');
    premium.vouchers.failVerifyWith = const PremiumVoucherFailure(
      PremiumVoucherProblem.emailCodeExpired,
    );
    await enterCode(tester, '333333');
    expect(tester.takeException(), isNull);
    await waitOutCooldown(tester);
  });
}
