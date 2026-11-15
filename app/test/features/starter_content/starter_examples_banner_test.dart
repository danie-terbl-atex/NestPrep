import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/starter_content/data/starter_content_repository.dart';
import 'package:nestprep/features/starter_content/ui/starter_examples_banner.dart';
import 'package:nestprep/shared/copy/starter_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';

import '../../support/fake_starter_content.dart';
import '../../support/household_fixtures.dart';
import '../../support/pump_kit.dart';

void main() {
  late FakeStarterContentRepository repository;

  setUp(() => repository = FakeStarterContentRepository());

  Future<void> pump(
    WidgetTester tester, {
    required List<String> shownIds,
    HouseholdView? view,
    Brightness brightness = Brightness.light,
  }) => pumpKit(
    tester,
    MultiProvider(
      providers: [
        Provider<HouseholdView>.value(value: view ?? Fixtures.view()),
        Provider<StarterContentRepository>.value(value: repository),
        Provider<HouseholdClock>.value(
          value: HouseholdClock('Africa/Johannesburg'),
        ),
      ],
      child: StarterExamplesBanner(shownIds: shownIds),
    ),
    brightness: brightness,
  );

  for (final brightness in bothThemes) {
    testWidgets('an admin looking at an example is told so ($brightness)', (
      tester,
    ) async {
      await pump(
        tester,
        shownIds: ['abc', 'starter-task-edit'],
        brightness: brightness,
      );
      expect(find.text(StarterCopy.bannerMessage), findsOneWidget);
      expect(find.text(StarterCopy.bannerAction), findsOneWidget);
    });
  }

  testWidgets('nothing once no example is on the screen', (tester) async {
    await pump(tester, shownIds: ['abc', 'def']);
    expect(find.text(StarterCopy.bannerMessage), findsNothing);
  });

  testWidgets('nothing for somebody the rules would refuse', (tester) async {
    await pump(
      tester,
      shownIds: ['starter-task-edit'],
      view: Fixtures.view(viewerUid: Fixtures.thandiUid),
    );
    expect(find.text(StarterCopy.bannerMessage), findsNothing);
  });

  testWidgets('clearing asks first, and keeping them clears nothing', (
    tester,
  ) async {
    await pump(tester, shownIds: ['starter-task-edit']);
    await tester.tap(find.text(StarterCopy.bannerAction));
    await tester.pumpAndSettle();
    expect(find.text(StarterCopy.clearTitle), findsOneWidget);

    await tester.tap(find.text(StarterCopy.clearCancel));
    await tester.pumpAndSettle();
    expect(repository.cleared, isEmpty);
  });

  testWidgets('confirming clears this household', (tester) async {
    await pump(tester, shownIds: ['starter-task-edit']);
    await tester.tap(find.text(StarterCopy.bannerAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(StarterCopy.clearConfirm));
    await tester.pumpAndSettle();
    expect(repository.cleared, [Fixtures.householdId]);
  });

  testWidgets('a refusal is said, and the notice stays usable', (tester) async {
    repository.clearFailure = const UnavailableFailure();
    await pump(tester, shownIds: ['starter-task-edit']);
    await tester.tap(find.text(StarterCopy.bannerAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(StarterCopy.clearConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(repository.cleared, isEmpty);
    expect(find.text(StarterCopy.bannerAction), findsOneWidget);
  });
}
