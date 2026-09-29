import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/checklist_item.dart';
import 'package:nestprep/features/nanny_hub/model/shift_moment.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  Future<void> open(
    WidgetTester tester,
    String location, {
    HouseholdView? view,
    bool filledIn = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpNannyHub(
      tester,
      fakes,
      location: location,
      view: view,
      brightness: brightness,
      textScale: textScale,
    );
    if (filledIn) {
      fakes.answerAFullHub();
    } else {
      fakes.answerEverything();
    }
    await tester.pumpAndSettle();
  }

  final rules = NannyHubRoute.rulesPathFor(Fixtures.householdId);
  final checklists = NannyHubRoute.checklistsPathFor(Fixtures.householdId);

  group('house rules', () {
    testWidgets('are listed for the carer to read', (tester) async {
      await open(tester, rules, view: NannyFixtures.lookOnlyCarerView());
      expect(find.text('No screens after six'), findsOneWidget);
      expect(find.text(NannyCopy.addRule), findsNothing);
    });

    testWidgets('an empty list says what belongs in it', (tester) async {
      await open(tester, rules, filledIn: false);
      expect(find.text(NannyCopy.rulesEmptyBody), findsOneWidget);
    });

    testWidgets('a parent adds one, and cannot add nothing', (tester) async {
      await open(tester, rules, filledIn: false);
      await tester.tap(find.text(NannyCopy.addRule));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      expect(fakes.hub.writes, isEmpty);
      await tester.enterText(fieldLabelled(NannyCopy.ruleText), 'Bed by 8 ');
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      final (method, arguments) = fakes.hub.writes.single;
      expect(method, 'addRule');
      expect(arguments['text'], 'Bed by 8');
    });

    testWidgets('a parent changes one', (tester) async {
      await open(tester, rules);
      await tester.tap(find.text('No screens after six'));
      await tester.pumpAndSettle();
      await tester.enterText(
        fieldLabelled(NannyCopy.ruleText),
        'No screens after seven',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      final (method, arguments) = fakes.hub.writes.single;
      expect(method, 'updateRule');
      expect(arguments, {
        'ruleId': 'r-screens',
        'text': 'No screens after seven',
      });
    });

    testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
      await open(tester, rules, brightness: Brightness.dark, textScale: 2);
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('shift checklists', () {
    testWidgets('show all five parts of a shift, in the order it meets them', (
      tester,
    ) async {
      await open(tester, checklists);
      for (final moment in ShiftMoment.values) {
        expect(find.text(NannyCopy.momentName(moment)), findsOneWidget);
      }
      expect(find.text('Brush teeth'), findsOneWidget);
      expect(find.text(NannyCopy.noChecklistItems), findsNWidgets(4));
    });

    testWidgets('a parent edits one: an item keeps its id, a new one has '
        'none until it is saved', (tester) async {
      await open(tester, checklists);
      await tester.tap(
        find.byTooltip(NannyCopy.editChecklist(ShiftMoment.bedtime)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.addItem));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(TextField).last,
          matching: find.byType(EditableText),
        ),
        'Night light on',
      );
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      final (method, arguments) = fakes.hub.writes.single;
      expect(method, 'saveChecklist');
      expect(arguments['moment'], ShiftMoment.bedtime);
      final items = (arguments['items']! as List<ChecklistItem>)
          .map((item) => item.id)
          .toList();
      expect(items, ['teeth', 'story', 'item-0']);
    });

    testWidgets('a carer at view reads them and changes nothing', (
      tester,
    ) async {
      await open(tester, checklists, view: NannyFixtures.lookOnlyCarerView());
      expect(
        find.byTooltip(NannyCopy.editChecklist(ShiftMoment.bedtime)),
        findsNothing,
      );
    });

    testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
      await open(tester, checklists, brightness: Brightness.dark, textScale: 2);
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
