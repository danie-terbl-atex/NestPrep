import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/app/household_place_redirect.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// The ways into home care's V2 parts from its front door (home-care
/// ADR-0004 to ADR-0006) — a capability with no way in is not done (the
/// vault lesson) — and each gone while its switch is off (foundation
/// ADR-0014).
void main() {
  late HomeCareHarness harness;

  setUp(() => harness = HomeCareHarness());
  tearDown(() => harness.close());

  testWidgets('a parent reaches the routines, the stock and the languages', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester);
    await harness.emit(tester);

    for (final (label, screenTitle) in [
      (HomeCareRoutineCopy.routines, HomeCareRoutineCopy.routinesSubtitle),
      (HomeCareStockCopy.stock, HomeCareStockCopy.subtitle),
      (HomeCareLanguageCopy.languages, HomeCareLanguageCopy.languagesSubtitle),
    ]) {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(screenTitle), findsOneWidget, reason: label);
      harness.router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a helper has today’s rooms first, big, and her own language', (
    tester,
  ) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, view: HomeCareFixtures.helperView());
    await harness.emit(tester);
    await harness.emitLanguages(tester, {
      Fixtures.thandiMemberId: HelperLanguage.isiXhosa,
    });

    expect(find.text(HomeCareRoutineCopy.todayBanner), findsOneWidget);
    expect(find.text(HomeCareRoutineCopy.routines), findsNothing);
    expect(find.text('isiXhosa'), findsOneWidget);

    await tester.tap(find.text(HomeCareRoutineCopy.today));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      harness.router.state.uri.path,
      HomeCareRoute.todayPathFor(Fixtures.householdId),
    );
  });

  testWidgets('every way in is gone while its switch is off', (tester) async {
    harness.flagsDefaultOn = false;
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester, view: HomeCareFixtures.helperView());
    await harness.emit(tester);

    expect(find.text(HomeCareRoutineCopy.today), findsNothing);
    expect(find.text(HomeCareStockCopy.stock), findsNothing);
    expect(find.text(HomeCareLanguageCopy.myLanguage), findsNothing);
    // The jobs are exactly as they were.
    expect(find.text('Grease on the oven door'), findsOneWidget);
  });

  testWidgets('one switch turned on shows its way in, and only that', (
    tester,
  ) async {
    harness.flagsDefaultOn = false;
    HomeCareHarness.makeRoom(tester);
    await harness.pump(tester);
    await harness.emit(tester);
    harness.flags.emit({'homeCareStock': true});
    await tester.pumpAndSettle();

    expect(find.text(HomeCareStockCopy.stock), findsOneWidget);
    expect(find.text(HomeCareRoutineCopy.routines), findsNothing);
  });

  group('a deep link', () {
    for (final path in [
      HomeCareRoute.routinesPathFor(Fixtures.householdId),
      HomeCareRoute.todayPathFor(Fixtures.householdId),
      HomeCareRoute.stockPathFor(Fixtures.householdId),
      HomeCareRoute.languagesPathFor(Fixtures.householdId),
    ]) {
      test('to $path is no way round a grant of none', () {
        expect(
          householdPlaceRedirect(
            location: path,
            view: HomeCareFixtures.noCleaningView(),
          ),
          isNotNull,
        );
      });
    }
  });
}
