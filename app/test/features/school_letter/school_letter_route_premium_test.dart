import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/calendar_v2_route.dart';
import 'package:nestprep/app/calendar_v2_routes.dart';
import 'package:nestprep/features/calendar/data/calendar_repository.dart';
import 'package:nestprep/features/school_letter/data/letter_picker.dart';
import 'package:nestprep/features/school_letter/data/school_letter_reader.dart';
import 'package:nestprep/features/school_letter/ui/school_letter_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:provider/provider.dart';

import '../../support/fake_calendar_repository.dart';
import '../../support/fake_calendar_v2.dart';
import '../../support/household_fixtures.dart';
import '../../support/pump_screen.dart';
import '../../support/pump_subscriptions.dart';

/// Snap a school letter is Premium (subscriptions ADR-0008): its address
/// shows the place locked to a household without Premium, and nothing behind
/// it starts.
void main() {
  late FakeSchoolLetterReader reader;
  late FakeLetterPicker picker;
  late FakeCalendarRepository calendar;
  late SubscriptionHarness subscriptions;

  setUp(() {
    reader = FakeSchoolLetterReader();
    picker = FakeLetterPicker();
    calendar = FakeCalendarRepository();
  });

  tearDown(() => calendar.close());

  Future<void> open(
    WidgetTester tester, {
    required bool isPremium,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    subscriptions = SubscriptionHarness(
      entitlement: isPremium
          ? Entitlement(premiumUntil: DateTime.utc(2100))
          : Entitlement.free,
    );
    final router = GoRouter(
      initialLocation: CalendarV2Route.letterPathFor(Fixtures.householdId),
      routes: [calendarV2Routes().first],
    );
    addTearDown(router.dispose);
    await pumpRouter(
      tester,
      router: router,
      providers: [
        ...subscriptions.providers,
        Provider<SchoolLetterReader>.value(value: reader),
        Provider<LetterPicker>.value(value: picker),
        Provider<CalendarRepository>.value(value: calendar),
      ],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a household with Premium gets the screen', (tester) async {
    await open(tester, isPremium: true);

    expect(find.byType(SchoolLetterScreen), findsOneWidget);
    expect(find.byType(PremiumLockedView), findsNothing);
  });

  testWidgets('a free household sees the place, locked, and the way in is '
      'the paywall on the school letter', (tester) async {
    await open(tester, isPremium: false);

    expect(tester.takeException(), isNull);
    expect(find.byType(SchoolLetterScreen), findsNothing);
    expect(find.text(SchoolLetterCopy.title), findsOneWidget);
    expect(find.byType(PremiumLockedView), findsOneWidget);
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.schoolLetter)),
      findsOneWidget,
    );
    expect(find.text(SchoolLetterCopy.takePhoto), findsNothing);
    expect(picker.asked, isEmpty);
    expect(reader.requests, isEmpty);

    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallPage), findsOneWidget);
    expect(
      subscriptions.paywallOpens.opened.single.trigger,
      PremiumFeature.schoolLetter,
    );
  });

  testWidgets('locked, it survives dark at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await open(tester, isPremium: false, brightness: Brightness.dark, scale: 2);

    expect(tester.takeException(), isNull);
    expect(find.byType(PremiumLockedView), findsOneWidget);
  });
}
