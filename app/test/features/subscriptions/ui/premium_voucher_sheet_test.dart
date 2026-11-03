import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher.dart';
import 'package:nestprep/features/subscriptions/ui/premium_voucher_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/premium_voucher_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_premium_vouchers.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// The claim sheet (subscriptions ADR-0003, ADR-0004): Premium from a frame
/// order or a gift, added to a household the viewer is family in, with every
/// refusal said on the voucher it belongs to — and never a code, a label or
/// a partner.
void main() {
  late SubscriptionHarness premium;
  late FakeHouseholdRepository households;

  const frame = FakePremiumVoucherDirectory.frame;
  const gift = FakePremiumVoucherDirectory.gift;

  const gran = Household(
    id: 'h2',
    name: 'Gran’s house',
    timeZone: 'Africa/Johannesburg',
    members: {Fixtures.samUid: 'parent'},
  );
  const helping = Household(
    id: 'h3',
    name: 'The Smiths',
    timeZone: 'Africa/Johannesburg',
    members: {Fixtures.samUid: 'helper'},
  );

  ({SessionController session, Future<void> Function(WidgetTester) signIn})
  sessionIn(List<String> householdIds) {
    final auth = FakeAuthGateway();
    final accounts = FakeAccountRepository();
    final session = SessionController(
      authGateway: auth,
      accountRepository: accounts,
    );
    addTearDown(() async {
      session.dispose();
      await auth.close();
      await accounts.close();
    });
    Future<void> signIn(WidgetTester tester) async {
      auth.emit(
        const AuthUser(uid: Fixtures.samUid, email: 'sam@nestprep.test'),
      );
      await tester.pumpAndSettle();
      accounts.emit(
        Account(
          id: Fixtures.samUid,
          displayName: 'Sam Parent',
          householdIds: householdIds,
          activeHouseholdId: Fixtures.householdId,
        ),
      );
    }

    return (session: session, signIn: signIn);
  }

  Future<void> openSheet(
    WidgetTester tester, {
    List<PremiumVoucher> waiting = const [frame],
    List<String>? householdIds,
    AppFailure? householdsFail,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    premium = SubscriptionHarness();
    premium.vouchers.waiting = [...waiting];
    households = FakeHouseholdRepository()
      ..storedHouseholds.addAll({gran.id: gran, helping.id: helping})
      ..failWritesWith = householdsFail;
    addTearDown(households.close);
    premium.inbox.attach(Fixtures.samUid);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final ids = householdIds;
    final signedIn = ids == null ? null : sessionIn(ids);
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showPremiumVoucherSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
      providers: <SingleChildWidget>[
        ...premium.providers,
        Provider<HouseholdRepository>.value(value: households),
        if (signedIn != null)
          ChangeNotifierProvider<SessionController>.value(
            value: signedIn.session,
          ),
      ],
      brightness: brightness,
      textScale: textScale,
    );
    if (signedIn != null) await signedIn.signIn(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder claimButton(PremiumVoucher voucher) =>
      find.byKey(ValueKey('claim-${voucher.voucherId}'));

  Future<void> claim(WidgetTester tester, PremiumVoucher voucher) async {
    await tester.ensureVisible(claimButton(voucher));
    await tester.tap(claimButton(voucher));
    await tester.pumpAndSettle();
  }

  testWidgets('one household: says what is waiting and adds it there', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text(PremiumVoucherCopy.sheetTitle), findsOneWidget);
    expect(
      find.text('3 months of Premium from your frame order'),
      findsOneWidget,
    );
    expect(
      find.text(PremiumVoucherCopy.sentTo('s***@gmail.com')),
      findsOneWidget,
    );
    expect(
      find.text(PremiumVoucherCopy.intoOnly('The Parkers')),
      findsOneWidget,
    );
    expect(find.text(PremiumVoucherCopy.chooseHousehold), findsNothing);

    await claim(tester, frame);

    expect(premium.vouchers.claimed, [
      (voucherId: frame.voucherId, householdId: Fixtures.householdId),
    ]);
    expect(find.text(PremiumVoucherCopy.added('The Parkers')), findsOneWidget);
    expect(claimButton(frame), findsNothing);
    expect(premium.inbox.waiting, isEmpty);
    expect(find.text(PremiumVoucherCopy.done), findsOneWidget);
  });

  testWidgets('a gift reads in days, and says it is waiting', (tester) async {
    await openSheet(tester, waiting: [gift]);
    expect(find.text('30 days of Premium waiting for you'), findsOneWidget);
  });

  testWidgets('a paying household hears that it starts when paid time ends', (
    tester,
  ) async {
    await openSheet(tester);
    premium.vouchers.queued = true;
    await claim(tester, frame);
    expect(
      find.text(PremiumVoucherCopy.addedQueued('The Parkers')),
      findsOneWidget,
    );
    expect(find.text(PremiumVoucherCopy.added('The Parkers')), findsNothing);
  });

  testWidgets('several households: only family ones, and the one chosen', (
    tester,
  ) async {
    await openSheet(
      tester,
      waiting: [frame, gift],
      householdIds: [Fixtures.householdId, gran.id, helping.id],
    );

    expect(find.text(PremiumVoucherCopy.chooseHousehold), findsOneWidget);
    expect(find.text('The Parkers'), findsOneWidget);
    expect(find.text(gran.name), findsOneWidget);
    expect(find.text(helping.name), findsNothing);
    expect(
      find.text(PremiumVoucherCopy.addTo('The Parkers')),
      findsNWidgets(2),
    );

    await tester.tap(find.byKey(ValueKey('voucher-household-${gran.id}')));
    await tester.pumpAndSettle();
    expect(find.text(PremiumVoucherCopy.addTo(gran.name)), findsNWidgets(2));

    await claim(tester, gift);
    expect(premium.vouchers.claimed.single.householdId, gran.id);
    expect(find.text(PremiumVoucherCopy.added(gran.name)), findsOneWidget);
    expect(claimButton(frame), findsOneWidget);
  });

  testWidgets('a household list it cannot read still offers this household', (
    tester,
  ) async {
    await openSheet(
      tester,
      householdIds: [Fixtures.householdId, gran.id],
      householdsFail: const UnavailableFailure(),
    );
    expect(find.text(PremiumVoucherCopy.chooseHousehold), findsNothing);
    expect(
      find.text(PremiumVoucherCopy.intoOnly('The Parkers')),
      findsOneWidget,
    );
    await claim(tester, frame);
    expect(premium.vouchers.claimed.single.householdId, Fixtures.householdId);
  });

  group('every refusal is said on the voucher', () {
    final refusals = <AppFailure>[
      for (final problem in PremiumVoucherProblem.values)
        if (!problem.name.startsWith('email') &&
            problem != PremiumVoucherProblem.tooManyCodes)
          PremiumVoucherFailure(problem),
      const PremiumVoucherFailure(
        PremiumVoucherProblem.codeAlreadyUsed,
        scope: VoucherRefusalScope.person,
      ),
      const PremiumVoucherFailure(
        PremiumVoucherProblem.codeAlreadyUsed,
        scope: VoucherRefusalScope.household,
      ),
      const HouseholdFailure(HouseholdProblem.notAMember),
      const HouseholdFailure(HouseholdProblem.householdNotFound),
      const UnavailableFailure(),
    ];

    for (final refusal in refusals) {
      final name = switch (refusal) {
        PremiumVoucherFailure(:final problem, :final scope) =>
          '${problem.name}${scope == null ? '' : ' (${scope.name})'}',
        HouseholdFailure(:final problem) => problem.name,
        _ => refusal.runtimeType.toString(),
      };
      testWidgets(name, (tester) async {
        await openSheet(tester, waiting: [gift]);
        premium.vouchers.failClaimWith = refusal;
        await claim(tester, gift);

        expect(find.text(AppCopy.failure(refusal)), findsOneWidget);
        final ends = refusal is PremiumVoucherFailure && refusal.endsVoucher;
        expect(claimButton(gift), ends ? findsNothing : findsOneWidget);
        expect(premium.inbox.waiting, ends ? isEmpty : [gift]);
      });
    }

    test('the ones a different household could take keep the voucher', () {
      bool ends(PremiumVoucherProblem problem, [VoucherRefusalScope? scope]) =>
          PremiumVoucherFailure(problem, scope: scope).endsVoucher;
      expect(ends(PremiumVoucherProblem.codeNotEligible), isFalse);
      expect(ends(PremiumVoucherProblem.codeYearlyLimit), isFalse);
      expect(ends(PremiumVoucherProblem.codePaused), isFalse);
      expect(
        ends(
          PremiumVoucherProblem.codeAlreadyUsed,
          VoucherRefusalScope.household,
        ),
        isFalse,
      );
      expect(
        ends(PremiumVoucherProblem.codeAlreadyUsed, VoucherRefusalScope.person),
        isTrue,
      );
      expect(ends(PremiumVoucherProblem.voucherClaimed), isTrue);
    });
  });

  testWidgets('a refusal for one household clears when another is chosen', (
    tester,
  ) async {
    await openSheet(
      tester,
      waiting: [gift],
      householdIds: [Fixtures.householdId, gran.id],
    );
    const refusal = PremiumVoucherFailure(
      PremiumVoucherProblem.codeNotEligible,
    );
    premium.vouchers.failClaimWith = refusal;
    await claim(tester, gift);
    expect(find.text(AppCopy.failure(refusal)), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('voucher-household-${gran.id}')));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.failure(refusal)), findsNothing);
  });

  testWidgets('never names a code, a partner or where a gift is redeemed', (
    tester,
  ) async {
    await openSheet(tester, waiting: [frame, gift]);
    for (final word in ['redeem', 'partner', 'label', '/redeem']) {
      expect(find.textContaining(word, findRichText: true), findsNothing);
    }
    expect(find.textContaining(RegExp(r'\bcode\b')), findsNothing);
  });

  testWidgets('a test order says so', (tester) async {
    await openSheet(tester, waiting: [frame.copyWith(isTest: true)]);
    expect(find.text(PremiumVoucherCopy.testOrder), findsOneWidget);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await openSheet(
      tester,
      waiting: [frame.copyWith(isTest: true), gift],
      householdIds: [Fixtures.householdId, gran.id],
      brightness: Brightness.dark,
      textScale: 2,
    );
    await claim(tester, frame);
    expect(tester.takeException(), isNull);
  });
}
