import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/list_scan/model/list_reading.dart';
import 'package:nestprep/features/list_scan/state/list_scan_controller.dart';
import 'package:nestprep/features/list_scan/ui/list_scan_screen.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/recipes/data/recipe_groceries.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../support/fake_feature_flag_source.dart';
import '../../support/fake_grocery_repository.dart';
import '../../support/fake_list_scan.dart';
import '../../support/household_fixtures.dart';
import '../../support/pump_screen.dart';

/// Snap a shopping list, as the member sees it (list-scan ADR-0001): every
/// step drawn, and nothing on the grocery list until a button says so.
void main() {
  late FakeListScanReader reader;
  late FakeListPhotoPicker picker;
  late FakeGroceryRepository groceries;

  setUp(() {
    reader = FakeListScanReader();
    picker = FakeListPhotoPicker();
    groceries = FakeGroceryRepository();
  });

  tearDown(() => groceries.close());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool shopsOn = false,
  }) async {
    final flags = FakeFeatureFlagSource();
    addTearDown(flags.close);
    await pumpScreen(
      tester,
      const ListScanScreen(memberId: Fixtures.samMemberId),
      brightness: brightness,
      textScale: textScale,
      providers: [
        featureFlagsProvider(defaultOn: shopsOn, source: flags),
        ChangeNotifierProvider(
          create: (_) => ListScanController(
            listScanReader: reader,
            listPhotoPicker: picker,
            groceries: RecipeGroceries(
              groceryRepository: groceries,
              matched: ShopWeekGroceries(
                groceryRepository: groceries,
                householdId: Fixtures.householdId,
                memberId: Fixtures.samMemberId,
              ),
              householdId: Fixtures.householdId,
              memberId: Fixtures.samMemberId,
            ),
            householdId: Fixtures.householdId,
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(
      tester.element(find.text(text).last),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Taps [text] and answers each read of the grocery list with [list].
  Future<void> tapAdding(
    WidgetTester tester,
    String text, [
    List<GroceryItem> list = const [],
  ]) async {
    await tester.tap(find.text(text));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      groceries.emitItems(list);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the two ways in, and says what leaves the phone', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(ListScanCopy.heroTitle), findsOneWidget);
    expect(find.text(ListScanCopy.takePhoto), findsOneWidget);
    expect(find.text(ListScanCopy.choosePhoto), findsOneWidget);
    expect(find.text(ListScanCopy.privacyBody), findsOneWidget);
  });

  testWidgets('says it is reading while the model has the photo', (
    tester,
  ) async {
    reader.gate = Completer<void>();
    await pump(tester);
    await tester.tap(find.text(ListScanCopy.takePhoto));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(ListScanCopy.readingTitle), findsOneWidget);
    reader.complete();
    await tester.pumpAndSettle();
    expect(find.text(ListScanCopy.found(3)), findsOneWidget);
  });

  testWidgets('shows every line ticked, and adds only what stays ticked', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, ListScanCopy.choosePhoto);
    expect(find.text('Full cream milk'), findsOneWidget);
    expect(find.text('2 l'), findsOneWidget);
    expect(find.text(AiCopy.callsLeft(97)), findsOneWidget);
    expect(find.text(ListScanCopy.addToList(3)), findsOneWidget);
    expect(groceries.added, isEmpty);

    await tap(tester, 'Brown bread');
    expect(find.text(ListScanCopy.addToList(2)), findsOneWidget);
    await tapAdding(tester, ListScanCopy.addToList(2));

    expect(groceries.added.map((line) => line.name), [
      'Full cream milk',
      'Bananas',
    ]);
    expect(find.text(ListScanCopy.addedTitle(2)), findsOneWidget);
    await tap(tester, ListScanCopy.snapAnother);
    expect(find.text(ListScanCopy.heroTitle), findsOneWidget);
  });

  testWidgets('Change fixes a name and how much, or leaves the line off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester);
    await tap(tester, ListScanCopy.takePhoto);

    await tester.tap(find.bySemanticsLabel(ListScanCopy.change('Brown bread')));
    await tester.pumpAndSettle();
    expect(find.text(ListScanCopy.editTitle), findsOneWidget);
    final name = find.byWidgetPredicate(
      (widget) =>
          widget is EditableText && widget.controller.text == 'Brown bread',
    );
    await tester.enterText(name, 'Seed loaf');
    await tester.tap(find.text(ListScanCopy.save));
    await tester.pumpAndSettle();
    expect(find.text('Seed loaf'), findsOneWidget);
    expect(find.text('Brown bread'), findsNothing);

    await tester.tap(
      find.bySemanticsLabel(ListScanCopy.change('Full cream milk')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ListScanCopy.remove));
    await tester.pumpAndSettle();
    expect(find.text(ListScanCopy.addToList(2)), findsOneWidget);
    expect(groceries.added, isEmpty, reason: 'changed, not added');
  });

  testWidgets('offers the shop only when one is switched on', (tester) async {
    await pump(tester);
    await tap(tester, ListScanCopy.takePhoto);
    expect(find.byKey(const ValueKey('list-scan-find')), findsNothing);
  });

  testWidgets('with both shops on, offers to find at the member’s shop', (
    tester,
  ) async {
    await pump(tester, shopsOn: true);
    await tap(tester, ListScanCopy.takePhoto);
    expect(find.text(ListScanCopy.findAtYourShop), findsOneWidget);
    expect(
      find.text(ListScanCopy.findAt(ProductRetailer.checkers)),
      findsNothing,
    );
  });

  testWidgets('a photo with no list says so in place, with the way on', (
    tester,
  ) async {
    reader.reading = const ListReading(lines: [], callsLeft: 5);
    await pump(tester);
    await tap(tester, ListScanCopy.takePhoto);
    expect(find.text(ListScanCopy.noneTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('list-scan-add')), findsNothing);
    await tap(tester, ListScanCopy.tryAnother);
    expect(find.text(ListScanCopy.heroTitle), findsOneWidget);
  });

  testWidgets('a spent month is said in words, with the way to try again', (
    tester,
  ) async {
    reader.failWith = const AiFailure(AiProblem.aiLimitReached);
    await pump(tester);
    await tap(tester, ListScanCopy.takePhoto);
    expect(find.text(AiCopy.problem(AiProblem.aiLimitReached)), findsOneWidget);

    reader.failWith = null;
    await tap(tester, ListScanCopy.tryAgain);
    expect(find.text(ListScanCopy.found(3)), findsOneWidget);
  });

  testWidgets('a write that fails keeps the lines, with the reason', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, ListScanCopy.takePhoto);
    groceries.failWritesWith = const PermissionDeniedFailure();
    await tapAdding(tester, ListScanCopy.addToList(3));
    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(find.text('Bananas'), findsOneWidget);
  });

  group('Twig is there only where the AI reads (design-system ADR-0012)', () {
    Finder twig([NestTwigPose? pose]) => find.byWidgetPredicate(
      (widget) => widget is NestTwig && (pose == null || widget.pose == pose),
    );

    testWidgets('welcomes, thinks, and celebrates what was added', (
      tester,
    ) async {
      reader.gate = Completer<void>();
      await pump(tester);
      expect(twig(NestTwigPose.welcome), findsOneWidget);
      await tester.tap(find.text(ListScanCopy.takePhoto));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(twig(NestTwigPose.thinking), findsOneWidget);
      reader.complete();
      await tester.pumpAndSettle();
      await tapAdding(tester, ListScanCopy.addToList(3));
      expect(twig(NestTwigPose.celebrate), findsOneWidget);
    });

    testWidgets('a photo that could not be picked comes back without Twig', (
      tester,
    ) async {
      picker.failWith = const ListScanFailure(
        ListScanProblem.pickerUnavailable,
      );
      await pump(tester);
      await tap(tester, ListScanCopy.takePhoto);
      expect(twig(), findsNothing);
      expect(
        find.text(ListScanCopy.problem(ListScanProblem.pickerUnavailable)),
        findsOneWidget,
      );
    });
  });

  for (final step in ['choosing', 'review', 'done', 'failure']) {
    testWidgets('the $step step survives dark at 200% text on a 360-wide '
        'phone', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      if (step == 'failure') {
        reader.failWith = const AiFailure(AiProblem.aiUnavailable);
      }
      await pump(
        tester,
        brightness: Brightness.dark,
        textScale: 2,
        shopsOn: true,
      );
      if (step != 'choosing') await tap(tester, ListScanCopy.takePhoto);
      if (step == 'done') {
        await tester.ensureVisible(find.byKey(const ValueKey('list-scan-add')));
        await tester.pumpAndSettle();
        await tapAdding(tester, ListScanCopy.addToList(3));
        expect(find.text(ListScanCopy.addedTitle(3)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
