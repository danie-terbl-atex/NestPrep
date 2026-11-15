import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/two_homes_route.dart';
import 'package:nestprep/app/two_homes_routes.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/features/two_homes/data/two_homes_directory.dart';
import 'package:nestprep/features/two_homes/data/two_homes_repository.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/state/custody_calendar.dart';
import 'package:nestprep/features/two_homes/ui/custody_calendar_scope.dart';
import 'package:nestprep/features/two_homes/ui/locked_link_row.dart';
import 'package:nestprep/features/two_homes/ui/two_homes_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_invite_sharer.dart';
import '../../../support/fake_two_homes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/premium_entitlement.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// Two homes is Premium in full (subscriptions ADR-0008): a household without
/// it meets every address locked, never hidden, with nothing behind it
/// listening or calling — and no custody bands on its week. The list alone
/// reads the links, so an open one can still be ended.
void main() {
  late FakeTwoHomesRepository repository;
  late FakeTwoHomesDirectory directory;

  setUp(() {
    repository = FakeTwoHomesRepository();
    directory = FakeTwoHomesDirectory();
  });
  tearDown(() => repository.close());

  const id = Fixtures.householdId;
  final places = {
    'the list': (TwoHomesRoute.pathFor(id), TwoHomesCopy.title),
    'a new link': (
      TwoHomesRoute.setupPathFor(id),
      TwoHomesSetupCopy.setupTitle,
    ),
    'joining with a code': (
      TwoHomesRoute.joinPathFor(id),
      TwoHomesSetupCopy.joinTitle,
    ),
    'what the other home sees': (
      TwoHomesRoute.privacyPathFor(id),
      TwoHomesSetupCopy.privacyTitle,
    ),
    'a link': (TwoHomesRoute.linkPathFor(id, 'link-sam'), TwoHomesCopy.title),
    'a new schedule': (
      TwoHomesRoute.schedulePathFor(id, 'link-sam'),
      TwoHomesCopy.scheduleRequestTitle,
    ),
    'a handover': (
      TwoHomesRoute.handoverPathFor(id, 'link-sam', CalendarDate(2026, 10, 2)),
      TwoHomesHandoverCopy.title,
    ),
  };

  Future<SubscriptionHarness> open(
    WidgetTester tester, {
    String? location,
    HouseholdView? view,
    bool premium = false,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final subscriptions = SubscriptionHarness();
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: location ?? TwoHomesRoute.pathFor(id),
        routes: twoHomesRoutes(),
      ),
      view: view,
      brightness: brightness,
      textScale: textScale,
      providers: [
        Provider<TwoHomesRepository>.value(value: repository),
        Provider<TwoHomesDirectory>.value(value: directory),
        Provider<InviteSharer>.value(value: FakeInviteSharer()),
        ...subscriptions.providers,
        if (premium) premiumEntitlementProvider(),
      ],
    );
    await tester.pump();
    return subscriptions;
  }

  for (final MapEntry(key: place, value: (location, title)) in places.entries) {
    testWidgets('$place is locked without Premium, and nothing listens or '
        'calls', (tester) async {
      await open(tester, location: location);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.twoHomes)),
        findsOneWidget,
      );
      expect(
        repository.readsOpened,
        location == TwoHomesRoute.pathFor(id) ? ['links'] : isEmpty,
      );
      expect(directory.calls, isEmpty);
      expect(find.byType(LockedLinkRow), findsNothing);
    });
  }

  group('the locked list still lets a link be ended', () {
    testWidgets('an admin sees an active link and ends it', (tester) async {
      await open(tester);
      repository.links.add([aLink()]);
      await tester.pumpAndSettle();

      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(dadsHome.name), findsOneWidget);
      expect(repository.readsOpened, ['links']);

      await tester.ensureVisible(find.text(TwoHomesCopy.endLink));
      await tester.tap(find.text(TwoHomesCopy.endLink));
      await tester.pumpAndSettle();
      expect(find.text(TwoHomesCopy.endQuestion(dadsHome.name)), findsOne);
      expect(directory.calls, isEmpty);

      await tester.tap(find.text(TwoHomesCopy.endConfirm).last);
      await tester.pumpAndSettle();
      expect(directory.names, ['endLink']);
      expect(directory.lastOf('endLink'), {'linkId': 'link-sam'});

      repository.links.add([aLink(status: LinkStatus.ended)]);
      await tester.pumpAndSettle();
      expect(find.byType(LockedLinkRow), findsNothing);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeping the link calls nothing', (tester) async {
      await open(tester);
      repository.links.add([aLink()]);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(TwoHomesCopy.endLink));
      await tester.tap(find.text(TwoHomesCopy.endLink));
      await tester.pumpAndSettle();
      await tester.tap(find.text(TwoHomesCopy.endCancel));
      await tester.pumpAndSettle();

      expect(directory.calls, isEmpty);
      expect(find.byType(LockedLinkRow), findsOneWidget);
    });

    testWidgets('an admin turns down a home that accepted their code', (
      tester,
    ) async {
      await open(tester);
      repository.links.add([
        aLink(status: LinkStatus.pending, awaitingSide: CustodySide.a),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(TwoHomesCopy.confirmYes), findsNothing);
      await tester.ensureVisible(find.text(TwoHomesCopy.confirmNo));
      await tester.tap(find.text(TwoHomesCopy.confirmNo));
      await tester.pumpAndSettle();

      expect(directory.names, ['confirmLink']);
      expect(directory.lastOf('confirmLink'), {
        'linkId': 'link-sam',
        'accept': false,
      });
    });

    testWidgets('an admin withdraws a link the other home has not confirmed', (
      tester,
    ) async {
      await open(tester);
      repository.links.add([
        aLink(status: LinkStatus.pending, awaitingSide: CustodySide.b),
      ]);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(TwoHomesCopy.withdraw));
      await tester.tap(find.text(TwoHomesCopy.withdraw));
      await tester.pumpAndSettle();

      expect(directory.names, ['endLink']);
    });

    testWidgets('somebody who may not end a link sees it with no action', (
      tester,
    ) async {
      await open(
        tester,
        view: Fixtures.helperView(AccessGrant.uniform(AccessLevel.edit)),
      );
      repository.links.add([aLink()]);
      await tester.pumpAndSettle();

      expect(find.text(dadsHome.name), findsOneWidget);
      expect(find.text(TwoHomesCopy.endLink), findsNothing);
      expect(find.byType(NestButton), findsOneWidget);
      expect(directory.calls, isEmpty);
    });

    testWidgets('ended and declined links leave the plain locked place', (
      tester,
    ) async {
      await open(tester);
      repository.links.add([aLink(status: LinkStatus.ended)]);
      await tester.pumpAndSettle();

      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.byType(LockedLinkRow), findsNothing);
      expect(find.text(TwoHomesCopy.linkedChildren), findsNothing);
    });

    testWidgets('links that cannot be read leave the plain locked place', (
      tester,
    ) async {
      await open(tester);
      repository.links.addError(const UnknownFailure('refused'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.byType(LockedLinkRow), findsNothing);
    });

    testWidgets('a refused ending says so and keeps the row', (tester) async {
      await open(tester);
      repository.links.add([aLink()]);
      await tester.pumpAndSettle();
      directory.failWith = const UnknownFailure('offline');

      await tester.ensureVisible(find.text(TwoHomesCopy.endLink));
      await tester.tap(find.text(TwoHomesCopy.endLink));
      await tester.pumpAndSettle();
      await tester.tap(find.text(TwoHomesCopy.endConfirm).last);
      await tester.pumpAndSettle();

      expect(find.byType(NestBanner), findsOneWidget);
      expect(find.byType(LockedLinkRow), findsOneWidget);
    });

    testWidgets('holds in dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await open(tester, brightness: Brightness.dark, textScale: 2);
      repository.links.add([
        aLink(
          status: LinkStatus.pending,
          awaitingSide: CustodySide.a,
        ).copyWith(id: 'link-waiting'),
        aLink(),
      ]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final list = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text(TwoHomesCopy.confirmNo),
        200,
        scrollable: list,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text(TwoHomesCopy.endLink),
        200,
        scrollable: list,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LockedLinkRow), findsWidgets);
    });
  });

  testWidgets('with Premium two homes opens', (tester) async {
    await open(tester, premium: true);
    repository.links.add(const []);
    await tester.pumpAndSettle();

    expect(find.byType(TwoHomesScreen), findsOneWidget);
    expect(find.byType(PremiumLockedView), findsNothing);
    expect(repository.readsOpened, contains('links'));
  });

  testWidgets('See Premium opens the paywall on two homes', (tester) async {
    final subscriptions = await open(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallPage), findsOneWidget);
    expect(
      subscriptions.paywallOpens.opened.single.trigger,
      PremiumFeature.twoHomes,
    );
  });

  testWidgets('the locked place and its paywall hold in dark at 200% text on '
      'a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await open(
      tester,
      location: TwoHomesRoute.schedulePathFor(id, 'link-sam'),
      brightness: Brightness.dark,
      textScale: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PremiumLockedView), findsOneWidget);

    await tester.ensureVisible(find.text(SubscriptionCopy.seePremium));
    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('the week', () {
    Future<bool> hasBands(WidgetTester tester, {required bool premium}) async {
      late bool found;
      await pumpScreen(
        tester,
        CustodyCalendarScope(
          householdId: id,
          child: Builder(
            builder: (context) {
              found = context.watch<CustodyCalendar?>() != null;
              return const SizedBox();
            },
          ),
        ),
        providers: [
          Provider<TwoHomesRepository>.value(value: repository),
          if (premium) premiumEntitlementProvider(),
        ],
      );
      await tester.pump();
      return found;
    }

    testWidgets('draws no custody bands without Premium, and reads no link', (
      tester,
    ) async {
      expect(await hasBands(tester, premium: false), isFalse);
      expect(repository.readsOpened, isEmpty);
    });

    testWidgets('draws them with Premium', (tester) async {
      expect(await hasBands(tester, premium: true), isTrue);
      expect(repository.readsOpened, contains('links'));
    });
  });
}
