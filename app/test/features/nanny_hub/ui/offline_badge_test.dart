import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';
import '../../../support/test_flags.dart';

/// Works offline (nanny-hub ADR-0007): the emergency sheet and every child
/// card say whether this phone can show them without a signal, and when they
/// were last synced — and the line is the way to save when they are not.
void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  Future<void> openSheet(
    WidgetTester tester, {
    FeatureFlags flags = TestFlags.on,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.emergencyPathFor(Fixtures.householdId),
      view: NannyFixtures.carerView(),
      flags: flags,
      brightness: brightness,
      textScale: textScale,
    );
    fakes.answerAFullHub();
    await tester.pumpAndSettle();
  }

  testWidgets('a sheet not yet saved says so, and one tap saves it with its '
      'photos', (tester) async {
    fakes.warmer.photoIds = {'photo-shelf-01'};
    await openSheet(tester);
    expect(find.text(NannyOfflineCopy.notSaved), findsOneWidget);

    await tester.tap(find.text(NannyOfflineCopy.notSaved));
    await tester.pumpAndSettle();

    expect(fakes.warmer.requests, hasLength(1));
    expect(find.text(NannyOfflineCopy.saved), findsOneWidget);
    expect(
      find.textContaining(NannyOfflineCopy.lastSynced('')),
      findsOneWidget,
    );
  });

  testWidgets('with no signal and nothing saved, it says both, and offers to '
      'try again', (tester) async {
    fakes.warmer.failWith = const UnavailableFailure();
    await openSheet(tester);
    await tester.tap(find.text(NannyOfflineCopy.notSaved));
    await tester.pumpAndSettle();
    expect(find.text(NannyOfflineCopy.noSignal), findsOneWidget);
    expect(find.text(NannyOfflineCopy.nothingSaved), findsOneWidget);

    fakes.warmer.failWith = null;
    await tester.tap(find.text(NannyOfflineCopy.noSignal));
    await tester.pumpAndSettle();
    expect(find.text(NannyOfflineCopy.saved), findsOneWidget);
  });

  testWidgets('the public numbers still come first', (tester) async {
    await openSheet(tester);
    final numbersY = tester.getTopLeft(find.text(NannyCopy.emergencyIntro)).dy;
    final offlineY = tester.getTopLeft(find.text(NannyOfflineCopy.notSaved)).dy;
    expect(numbersY, lessThan(offlineY));
  });

  testWidgets('a child’s card says it too, after everything about the child', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.childPathFor(
        Fixtures.householdId,
        Fixtures.kidMemberId,
      ),
      view: NannyFixtures.carerView(),
    );
    fakes.answerAFullHub();
    await tester.pump();
    fakes.family.emitHealth(const MemberHealth(id: Fixtures.kidMemberId));
    await tester.pumpAndSettle();
    final offline = find.text(NannyOfflineCopy.notSaved);
    expect(offline, findsOneWidget);
    final allergiesY = tester.getTopLeft(find.text(NannyCopy.allergies)).dy;
    expect(allergiesY, lessThan(tester.getTopLeft(offline).dy));
  });

  testWidgets('switched off, there is no offline line', (tester) async {
    await openSheet(tester, flags: TestFlags.off);
    expect(find.text(NannyOfflineCopy.notSaved), findsNothing);
    expect(find.text(NannyCopy.emergencyIntro), findsOneWidget);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    fakes.warmer.failWith = const UnavailableFailure();
    await openSheet(tester, brightness: Brightness.dark, textScale: 2);
    await scrollTo(tester, find.text(NannyOfflineCopy.notSaved));
    await tester.tap(find.text(NannyOfflineCopy.notSaved));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
