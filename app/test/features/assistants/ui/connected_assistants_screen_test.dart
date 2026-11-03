import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/assistants/model/assistant_scope.dart';
import 'package:nestprep/features/assistants/state/connected_assistants_controller.dart';
import 'package:nestprep/features/assistants/ui/connected_assistants_screen.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_assistants.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// *Connected assistants* (assistants ADR-0001, ADR-0003) in both themes:
/// nothing connected, the viewer's own and another parent's, disconnecting
/// after a yes, the household's switch for family only, and each action
/// refused in the app's own words.
const _leeUid = 'uid-lee';
const _leeMemberId = 'm-lee';

const _lee = Member(
  id: _leeMemberId,
  displayName: 'Lee Parent',
  color: MemberColor.sky,
  roleName: 'parent',
  claimedBy: _leeUid,
);

HouseholdView _view(String viewerUid) => HouseholdView(
  household: Fixtures.household().copyWith(
    members: const {
      Fixtures.samUid: 'admin',
      _leeUid: 'parent',
      Fixtures.thandiUid: 'helper',
    },
  ),
  members: [Fixtures.sam, _lee, Fixtures.thandi, Fixtures.kid],
  viewerUid: viewerUid,
);

void main() {
  late FakeAssistantRepository repository;

  setUp(() => repository = FakeAssistantRepository());
  tearDown(() => repository.close());

  Future<void> pump(
    WidgetTester tester, {
    String viewerUid = Fixtures.samUid,
    String viewerMemberId = Fixtures.samMemberId,
    bool isFamily = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool tall = true,
  }) async {
    if (tall) {
      tester.view.physicalSize = const Size(420 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }
    final controller = ConnectedAssistantsController(
      assistantRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => assistantsNow,
      ),
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
      viewerMemberId: viewerMemberId,
      isFamily: isFamily,
    );
    addTearDown(controller.dispose);
    await pumpScreen(
      tester,
      const ConnectedAssistantsScreen(),
      providers: [
        ChangeNotifierProvider<ConnectedAssistantsController>.value(
          value: controller,
        ),
      ],
      view: _view(viewerUid),
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pump();
  }

  Finder inCard(String connectionId, String text) => find.descendant(
    of: find.byKey(ValueKey(connectionId)),
    matching: find.text(text),
  );

  Future<void> disconnect(WidgetTester tester, String connectionId) async {
    await tester.tap(inCard(connectionId, AssistantsCopy.disconnect));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text(AssistantsCopy.disconnect).last);
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      testWidgets('nothing connected says how to connect, with the address', (
        tester,
      ) async {
        await pump(tester, brightness: brightness);
        repository
          ..emitConnections([])
          ..emitAllowed(true);
        await tester.pumpAndSettle();

        expect(find.text(AssistantsCopy.emptyTitle), findsOneWidget);
        expect(find.text(AssistantsCopy.emptyBody), findsOneWidget);
        expect(find.text(AssistantsCopy.connectInClaude), findsOneWidget);
        expect(find.text(AssistantsCopy.connectAddress), findsOneWidget);
        expect(find.text(AssistantsCopy.copyAddress), findsOneWidget);
      });

      testWidgets('somebody who is not family is told parents connect them, '
          'and sees no switch and no way to connect', (tester) async {
        await pump(
          tester,
          viewerUid: Fixtures.thandiUid,
          viewerMemberId: Fixtures.thandiMemberId,
          isFamily: false,
          brightness: brightness,
        );
        repository.emitConnections([]);
        await tester.pumpAndSettle();

        expect(find.text(AssistantsCopy.emptyBodyForOthers), findsOneWidget);
        expect(find.text(AssistantsCopy.allowTitle), findsNothing);
        expect(find.byType(Switch), findsNothing);
        expect(find.text(AssistantsCopy.connectInClaude), findsNothing);
      });

      testWidgets('family see their own and another parent’s, each saying '
          'whose it is, what it may do and what it did', (tester) async {
        await pump(tester, brightness: brightness);
        repository
          ..emitConnections([
            claudeConnection(
              id: 'g-lee',
              uid: _leeUid,
              memberId: _leeMemberId,
              clientName: 'ChatGPT',
              scopes: const ['lists:read', 'lists:write'],
              lastUsedAgo: null,
            ),
            claudeConnection(),
          ])
          ..emitActivity([
            assistantActivity('a1'),
            assistantActivity(
              'a2',
              tool: 'add_grocery_items',
              ago: const Duration(hours: 3),
            ),
          ])
          ..emitAllowed(true);
        await tester.pumpAndSettle();

        expect(inCard('g-sam', 'Claude'), findsOneWidget);
        expect(inCard('g-sam', AssistantsCopy.connectedByYou), findsOneWidget);
        expect(
          inCard('g-sam', AssistantsCopy.inHousehold('The Parkers')),
          findsOneWidget,
        );
        for (final scope in AssistantScope.values) {
          expect(inCard('g-sam', AssistantsCopy.scope(scope)), findsOneWidget);
        }
        expect(
          inCard('g-sam', 'Connected Tue 20 Oct · Last used 2 hours ago'),
          findsOneWidget,
        );
        expect(
          inCard('g-sam', 'Added an event · 30 minutes ago'),
          findsOneWidget,
        );
        expect(
          inCard('g-sam', 'Added groceries · 3 hours ago'),
          findsOneWidget,
        );

        expect(inCard('g-lee', 'ChatGPT'), findsOneWidget);
        expect(
          inCard('g-lee', AssistantsCopy.connectedBy('Lee Parent')),
          findsOneWidget,
        );
        expect(
          inCard('g-lee', AssistantsCopy.scope(AssistantScope.calendarWrite)),
          findsNothing,
        );
        expect(
          inCard(
            'g-lee',
            'Connected Tue 20 Oct · ${AssistantsCopy.notUsedYet}',
          ),
          findsOneWidget,
        );
        expect(inCard('g-lee', AssistantsCopy.nothingYet), findsOneWidget);
        expect(inCard('g-lee', AssistantsCopy.disconnect), findsOneWidget);
      });

      testWidgets('disconnecting asks first, then deletes the grant', (
        tester,
      ) async {
        await pump(tester, brightness: brightness);
        repository.emitConnections([
          claudeConnection(),
          claudeConnection(id: 'g-lee', uid: _leeUid, memberId: _leeMemberId),
        ]);
        await tester.pumpAndSettle();

        await disconnect(tester, 'g-lee');
        expect(find.text(AssistantsCopy.disconnectConfirm), findsOneWidget);
        await tester.tap(find.text(AppCopy.householdCancel));
        await tester.pumpAndSettle();
        expect(repository.disconnected, isEmpty);

        await disconnect(tester, 'g-lee');
        await confirm(tester);
        expect(repository.disconnected, ['g-lee']);
        expect(find.byKey(const ValueKey('g-lee')), findsNothing);
        expect(find.byKey(const ValueKey('g-sam')), findsOneWidget);
      });

      for (final failure in const <AppFailure>[
        UnavailableFailure(),
        PermissionDeniedFailure(),
      ]) {
        testWidgets(
          'a disconnect refused (${failure.runtimeType}) says why in the '
          'app’s words, and the assistant stays',
          (tester) async {
            await pump(tester, brightness: brightness);
            repository
              ..emitConnections([claudeConnection()])
              ..failWritesWith = failure;
            await tester.pumpAndSettle();

            await disconnect(tester, 'g-sam');
            await confirm(tester);
            expect(find.text(AppCopy.failure(failure)), findsOneWidget);
            expect(find.byKey(const ValueKey('g-sam')), findsOneWidget);
          },
        );
      }

      testWidgets('family switch the household’s assistants off', (
        tester,
      ) async {
        await pump(tester, brightness: brightness);
        repository
          ..emitConnections([])
          ..emitAllowed(true);
        await tester.pumpAndSettle();

        expect(find.text(AssistantsCopy.allowTitle), findsOneWidget);
        expect(find.text(AssistantsCopy.allowOnBody), findsOneWidget);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(repository.allowedWrites.single, (
          allowed: false,
          memberId: Fixtures.samMemberId,
        ));
        expect(find.text(AssistantsCopy.allowOffBody), findsOneWidget);
      });

      testWidgets('a switch flipped with no signal says so and stays put', (
        tester,
      ) async {
        await pump(tester, brightness: brightness);
        repository
          ..emitConnections([])
          ..emitAllowed(true)
          ..failWritesWith = const UnavailableFailure();
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(
          find.text(AppCopy.failure(const UnavailableFailure())),
          findsOneWidget,
        );
        expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      });

      testWidgets('a failed read is words and a retry, never the error', (
        tester,
      ) async {
        await pump(tester, brightness: brightness);
        repository.failConnectionsWith(const PermissionDeniedFailure());
        await tester.pumpAndSettle();
        expect(
          find.text(AppCopy.failure(const PermissionDeniedFailure())),
          findsOneWidget,
        );
        expect(find.text(AppCopy.retry), findsOneWidget);
      });
    });
  }

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, textScale: 2, tall: false);
    repository
      ..emitConnections([
        claudeConnection(),
        claudeConnection(id: 'g-lee', uid: _leeUid, memberId: _leeMemberId),
      ])
      ..emitActivity([assistantActivity('a1')])
      ..emitAllowed(false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
