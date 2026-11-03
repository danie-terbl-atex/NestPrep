import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/assistants/model/assistant_via.dart';
import 'package:nestprep/features/assistants/ui/assistant_via_mark.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/ui/event_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/grocery_list_harness.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';

/// The quiet *via Claude* mark on what an assistant added (assistants
/// ADR-0005): on the event's sheet and on the grocery row, in both themes,
/// said in full to a screen reader — and absent from what a person typed.
void main() {
  final today = CalendarDate.parse('2026-10-29');

  HouseholdEvent swimming({AssistantVia? via}) => HouseholdEvent(
    id: 'e1',
    title: 'Swimming',
    date: today,
    startMinute: 900,
    endMinute: 960,
    createdBy: Fixtures.samMemberId,
    createdVia: via,
  );

  Future<void> openSheet(
    WidgetTester tester,
    HouseholdEvent event,
    Brightness brightness,
  ) async {
    await pumpKit(
      tester,
      Builder(
        builder: (context) => NestButton(
          label: 'open',
          onPressed: () => showEventSheet(
            context: context,
            members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
            today: today,
            initialDate: today,
            existing: event,
          ),
        ),
      ),
      brightness: brightness,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      testWidgets('an event Claude made says so on its sheet', (tester) async {
        final semantics = tester.ensureSemantics();
        await openSheet(tester, swimming(via: AssistantVia.claude), brightness);
        expect(
          find.text(AssistantsCopy.via(AssistantVia.claude)),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(AssistantsCopy.viaSpoken(AssistantVia.claude)),
          findsOneWidget,
        );
        semantics.dispose();
      });

      testWidgets('an event a person made carries no mark', (tester) async {
        await openSheet(tester, swimming(), brightness);
        expect(find.byType(AssistantViaMark), findsNothing);
      });

      testWidgets('a grocery item ChatGPT added says so on its row', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final h = GroceryListHarness();
        await h.pump(tester, brightness: brightness);
        h.repository.emitItems([
          groceryItem(
            'Milk',
            id: 'milk',
          ).copyWith(addedVia: AssistantVia.chatgpt),
          groceryItem('Bread', id: 'bread'),
        ]);
        await tester.pumpAndSettle();

        expect(find.byType(AssistantViaMark), findsOneWidget);
        expect(
          find.text(AssistantsCopy.via(AssistantVia.chatgpt)),
          findsOneWidget,
        );
        expect(
          // The row reads as one node, so the mark is part of its label.
          find.bySemanticsLabel(
            RegExp(AssistantsCopy.viaSpoken(AssistantVia.chatgpt)),
          ),
          findsOneWidget,
        );
        semantics.dispose();
      });
    });
  }
}
