import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/data/account_repository.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/welcome_tour/model/tour_place.dart';
import 'package:nestprep/features/welcome_tour/model/tour_premium.dart';
import 'package:nestprep/features/welcome_tour/model/tour_stop.dart';
import 'package:nestprep/features/welcome_tour/model/tour_target.dart';
import 'package:nestprep/features/welcome_tour/model/tour_version.dart';
import 'package:nestprep/features/welcome_tour/state/tour_anchor_registry.dart';
import 'package:nestprep/features/welcome_tour/state/tour_controller.dart';
import 'package:nestprep/features/welcome_tour/ui/tour_anchor.dart';
import 'package:nestprep/features/welcome_tour/ui/welcome_tour_layer.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/wait_for_tour.dart';

/// The tour over real screens (welcome-tour ADR-0002): it opens the tab a
/// stop needs, finds the component — scrolling a lazy list to reach it —
/// spotlights it, falls back or moves on when it is not there, and records
/// the tour as it ends.
void main() {
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;
  late TourController tour;
  late GoRouter router;
  late int tappedUnderneath;

  String titleOf(TourTarget target, {bool isLookOnly = false}) =>
      TourCopy.title(target, isLookOnly: isLookOnly);

  /// A tab page: the bell in its header, a long lazy list with the lunch
  /// board's day near the top and its tools far below, and the bar.
  Widget page(String place) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              Text('on $place'),
              const Spacer(),
              TourAnchor(
                target: TourTarget.bell,
                child: IconButton(
                  onPressed: () => tappedUnderneath++,
                  icon: const Icon(Icons.notifications),
                  tooltip: 'bell',
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                if (place == 'lunch') ...[
                  const TourAnchor(
                    target: TourTarget.lunchDayPills,
                    child: SizedBox(height: 60, child: Text('pills')),
                  ),
                  const TourAnchor(
                    target: TourTarget.lunchDay,
                    child: SizedBox(height: 200, child: Text('day')),
                  ),
                ],
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 80, child: Text('row $i')),
                if (place == 'lunch')
                  const TourAnchor(
                    target: TourTarget.lunchTools,
                    child: SizedBox(height: 200, child: Text('tools')),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tappedUnderneath = 0;
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
    tour = TourController();
    final anchors = TourAnchorRegistry();
    addTearDown(() async {
      tour.dispose();
      session.dispose();
      await auth.close();
      await accounts.close();
    });
    router = GoRouter(
      initialLocation: '/households/h1/today',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider<TourController>.value(value: tour),
              Provider<TourAnchorRegistry>.value(value: anchors),
            ],
            child: WelcomeTourLayer(location: state.uri.path, child: child),
          ),
          routes: [
            GoRoute(
              path: '/households/:householdId/:place',
              builder: (context, state) =>
                  page(state.pathParameters['place'] ?? ''),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpRouter(
      tester,
      router: router,
      brightness: brightness,
      textScale: textScale,
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        Provider<AccountRepository>.value(value: accounts),
      ],
    );
    auth.emit(const AuthUser(uid: Fixtures.samUid, email: 'sam@test'));
    await tester.pumpAndSettle();
    accounts.emit(
      const Account(id: Fixtures.samUid, displayName: 'Sam'),
      seenTour: false,
    );
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester, List<TourStop> stops) async {
    tour.start(stops, finishOn: TourPlace.lunch);
    await waitForTour(tester);
  }

  const bell = TourStop(TourTarget.bell, place: TourPlace.today);
  const tools = TourStop(TourTarget.lunchTools, place: TourPlace.lunch);

  testWidgets('spotlights the component and says what it is', (tester) async {
    await pump(tester);
    await start(tester, const [bell, tools]);

    expect(find.text(titleOf(TourTarget.bell)), findsOneWidget);
    expect(find.text(TourCopy.stepOf(1, 2)), findsOneWidget);
    expect(find.text(TourCopy.back), findsNothing, reason: 'the first step');
  });

  testWidgets('opens the stop’s tab and scrolls its list to a component far '
      'below the fold', (tester) async {
    await pump(tester);
    await start(tester, const [bell, tools]);
    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await waitForTour(tester);

    expect(find.text('on lunch'), findsOneWidget);
    expect(find.text(titleOf(TourTarget.lunchTools)), findsOneWidget);
    expect(find.text('tools'), findsOneWidget);
  });

  testWidgets('a component that is not there falls back to the next best', (
    tester,
  ) async {
    await pump(tester);
    await start(tester, const [
      TourStop(
        TourTarget.lunchChildSwitcher,
        place: TourPlace.lunch,
        fallbacks: [TourTarget.lunchDayPills],
      ),
    ]);

    expect(find.text(titleOf(TourTarget.lunchDayPills)), findsOneWidget);
    expect(find.text(titleOf(TourTarget.lunchChildSwitcher)), findsNothing);
  });

  testWidgets('a component that is nowhere is skipped, never pointed at', (
    tester,
  ) async {
    await pump(tester);
    await start(tester, const [
      TourStop(TourTarget.mealsViews, place: TourPlace.meals),
      bell,
    ]);

    expect(find.text(titleOf(TourTarget.bell)), findsOneWidget);
    expect(find.text(TourCopy.stepOf(1, 1)), findsOneWidget);
  });

  testWidgets('Back on screen and the phone’s back both step back', (
    tester,
  ) async {
    await pump(tester);
    await start(tester, const [bell, tools]);
    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await waitForTour(tester);

    await tester.tap(find.byKey(const ValueKey('tour-back')));
    await waitForTour(tester);
    expect(find.text(titleOf(TourTarget.bell)), findsOneWidget);
    expect(find.text('on today'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await waitForTour(tester);
    await tester.binding.handlePopRoute();
    await waitForTour(tester);
    expect(find.text(titleOf(TourTarget.bell)), findsOneWidget);

    await tester.binding.handlePopRoute();
    await waitForTour(tester);
    expect(tour.isActive, isFalse, reason: 'back on the first step skips');
  });

  testWidgets('skipping records it and lands on Today', (tester) async {
    await pump(tester);
    await start(tester, const [tools, bell]);
    expect(find.text('on lunch'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tour-skip')));
    await waitForTour(tester);

    expect(tour.isActive, isFalse);
    expect(find.text('on today'), findsOneWidget);
    expect(accounts.seenTours, [TourVersion.current]);
  });

  testWidgets('finishing records it and lands where the tour finishes', (
    tester,
  ) async {
    await pump(tester);
    await start(tester, const [bell]);
    expect(find.text(TourCopy.planFirstLunch), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await waitForTour(tester);

    expect(tour.lastEnd, TourEnd.finished);
    expect(find.text('on lunch'), findsOneWidget);
    expect(accounts.seenTours, [TourVersion.current]);
  });

  testWidgets('a tap inside the spotlight goes on; the app underneath does '
      'nothing', (tester) async {
    await pump(tester);
    await start(tester, const [bell, tools]);
    await tester.tap(find.byTooltip('bell'), warnIfMissed: false);
    await waitForTour(tester);

    expect(tappedUnderneath, 0);
    expect(find.text(titleOf(TourTarget.lunchTools)), findsOneWidget);
  });

  testWidgets('a premium tool says so on its callout', (tester) async {
    await pump(tester);
    await start(tester, const [
      TourStop(
        TourTarget.lunchTools,
        place: TourPlace.lunch,
        premium: TourPremium.offered,
      ),
    ]);
    expect(find.text(SubscriptionCopy.premium), findsOneWidget);
  });

  testWidgets('the callout holds dark at 200% text on a small phone', (
    tester,
  ) async {
    await pump(tester, brightness: Brightness.dark, textScale: 2);
    await start(tester, const [
      TourStop(
        TourTarget.lunchPlanMyWeek,
        place: TourPlace.today,
        fallbacks: [TourTarget.bell],
        premium: TourPremium.offered,
      ),
      tools,
    ]);
    expect(tester.takeException(), isNull);
    expect(find.text(titleOf(TourTarget.bell)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await waitForTour(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(titleOf(TourTarget.lunchTools)), findsOneWidget);
    expect(find.text(AppCopy.back), findsOneWidget);
    expect(
      NestTheme.of(tester.element(find.text('on lunch'))).colors,
      isNotNull,
    );
  });
}
