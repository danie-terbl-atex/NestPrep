import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../support/household_fixtures.dart';
import '../support/pump_kit.dart';

/// The things a household does, and how somebody moves between them.
///
/// The bar is how every screen is reached, and a navigation bug here has
/// already shipped once — the household link replaced the location instead of
/// pushing it, and the system back button closed the app.
void main() {
  group('the tabs themselves', () {
    test('the bar is Today, Lunch, Week, Lists and More '
        '(design-system ADR-0009)', () {
      expect(HouseholdTab.inBar, [
        HouseholdTab.today,
        HouseholdTab.lunch,
        HouseholdTab.week,
        HouseholdTab.lists,
        HouseholdTab.more,
      ]);
      for (final tab in HouseholdTab.inBar) {
        expect(tab.barTab, tab, reason: tab.name);
      }
    });

    test('To do and Groceries light Lists; Meals lights More', () {
      expect(HouseholdTab.todos.barTab, HouseholdTab.lists);
      expect(HouseholdTab.groceries.barTab, HouseholdTab.lists);
      expect(HouseholdTab.meals.barTab, HouseholdTab.more);
    });

    test('Lists opens To do, or Groceries for somebody who may only shop', () {
      final parent = Fixtures.view().permissions;
      expect(HouseholdTab.lists.landingFor(parent), HouseholdTab.todos);
      expect(HouseholdTab.today.landingFor(parent), HouseholdTab.today);
    });

    test('a household opens on Today', () {
      expect(
        HouseholdRoute.homeFor(Fixtures.householdId),
        HouseholdRoute.pathFor(Fixtures.householdId, HouseholdTab.today),
      );
    });

    test('More is open to everybody, whatever their grant', () {
      expect(HouseholdTab.more.area, isNull);
      expect(
        HouseholdTab.more.isOpenTo(
          Fixtures.view(viewerUid: Fixtures.thandiUid).permissions,
        ),
        isTrue,
      );
    });

    test('each has words, not only an icon', () {
      // `FE-13`: an icon on its own is not a label.
      for (final tab in HouseholdTab.values) {
        expect(tab.label.trim(), isNotEmpty, reason: tab.name);
      }
      expect(
        HouseholdTab.values.map((tab) => tab.label).toSet(),
        hasLength(HouseholdTab.values.length),
        reason: 'two tabs with one name is a bar nobody can describe',
      );
    });

    test('and a URL segment that is its own name', () {
      // The segment is in the address; a mismatch is a link that opens the
      // wrong screen (`FE-17`).
      for (final tab in HouseholdTab.values) {
        expect(tab.segment, tab.name);
      }
    });
  });

  group('the route each tab points at', () {
    test('carries the household, so a link opens the right one', () {
      for (final tab in HouseholdTab.values) {
        final path = HouseholdRoute.pathFor(Fixtures.householdId, tab);
        expect(path, contains(Fixtures.householdId));
        expect(path, endsWith(tab.segment));
      }
    });

    test('and the household id can be read back out of it', () {
      final path = HouseholdRoute.pathFor(
        Fixtures.householdId,
        HouseholdTab.meals,
      );
      expect(
        path,
        HouseholdRoute.homeFor(
          Fixtures.householdId,
        ).replaceAll(HouseholdTab.today.segment, HouseholdTab.meals.segment),
      );
    });
  });

  group('the bar on screen', () {
    testWidgets('shows every tab, and says which one you are on', (
      tester,
    ) async {
      var chosen = HouseholdTab.week;
      await pumpKit(
        tester,
        Provider<HouseholdView>.value(
          value: Fixtures.view(),
          child: HouseholdTabBar(
            current: HouseholdTab.groceries,
            onSelect: (tab) => chosen = tab,
          ),
        ),
      );

      // The words reach a person through the semantics tree, which is
      // exactly what `FE-13` asks for.
      final handle = tester.ensureSemantics();
      await tester.pumpAndSettle();
      for (final tab in HouseholdTab.inBar) {
        expect(
          find.bySemanticsLabel(tab.label),
          findsOneWidget,
          reason: '${tab.name} has no label a screen reader can announce',
        );
      }
      handle.dispose();

      expect(
        find.bySemanticsLabel(AppCopy.tabMeals),
        findsNothing,
        reason: 'meals is on More, not in the bar',
      );

      await tester.tap(find.bySemanticsLabel(MoreCopy.tab));
      await tester.pumpAndSettle();
      expect(chosen, HouseholdTab.more);
    });

    testWidgets('shows every name as words on screen, not only an icon', (
      tester,
    ) async {
      await pumpKit(
        tester,
        Provider<HouseholdView>.value(
          value: Fixtures.view(),
          child: HouseholdTabBar(current: HouseholdTab.lunch, onSelect: (_) {}),
        ),
      );

      for (final tab in HouseholdTab.inBar) {
        expect(find.text(tab.label), findsOneWidget, reason: tab.name);
      }
    });

    testWidgets('lights up More while meals is open', (tester) async {
      await pumpKit(
        tester,
        Provider<HouseholdView>.value(
          value: Fixtures.view(),
          child: HouseholdTabBar(current: HouseholdTab.meals, onSelect: (_) {}),
        ),
      );

      final handle = tester.ensureSemantics();
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel(MoreCopy.tab)),
        matchesSemantics(
          label: MoreCopy.tab,
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(LunchCopy.tab)),
        isNot(matchesSemantics(isSelected: true)),
      );
      handle.dispose();
    });

    testWidgets('tapping the one you are on still answers', (tester) async {
      HouseholdTab? chosen;
      await pumpKit(
        tester,
        Provider<HouseholdView>.value(
          value: Fixtures.view(),
          child: HouseholdTabBar(
            current: HouseholdTab.todos,
            onSelect: (tab) => chosen = tab,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel(AppCopy.tabLists));
      await tester.pumpAndSettle();

      expect(
        chosen,
        HouseholdTab.lists,
        reason: 'the screen decides whether that means anything, not the bar',
      );
    });
  });
}
