import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/assistants/state/connected_assistants_controller.dart';
import 'package:nestprep/features/assistants/ui/connected_assistants_screen.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_assistants.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// *Connected assistants* in the design-review press (assistants ADR-0001,
/// ADR-0003): a parent's own Claude and the other parent's ChatGPT with what
/// each did lately, and a household with nothing connected yet — in both
/// themes, and at 200% text in the dark. Pictures to look at rather than
/// assertions: regenerate with
///
///     flutter test tool/assistants_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  const lee = Member(
    id: 'm-lee',
    displayName: 'Lee Parent',
    color: MemberColor.sky,
    roleName: 'parent',
    claimedBy: 'uid-lee',
  );

  final view = HouseholdView(
    household: Fixtures.household().copyWith(
      members: const {
        Fixtures.samUid: 'admin',
        'uid-lee': 'parent',
        Fixtures.thandiUid: 'helper',
      },
    ),
    members: [Fixtures.sam, lee, Fixtures.thandi, Fixtures.kid],
    viewerUid: Fixtures.samUid,
  );

  Future<void> captureAssistants(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required bool isEmpty,
    double textScale = 1,
  }) async {
    final repository = FakeAssistantRepository();
    addTearDown(repository.close);
    await captureScreen(
      tester,
      name,
      brightness: brightness,
      textScale: textScale,
      view: view,
      screen: ChangeNotifierProvider(
        create: (_) => ConnectedAssistantsController(
          assistantRepository: repository,
          householdClock: HouseholdClock(
            'Africa/Johannesburg',
            now: () => assistantsNow,
          ),
          householdId: Fixtures.householdId,
          viewerUid: Fixtures.samUid,
          viewerMemberId: Fixtures.samMemberId,
          isFamily: true,
        ),
        child: const ConnectedAssistantsScreen(),
      ),
      providers: const [],
      emit: () async {
        repository
          ..emitAllowed(true)
          ..emitConnections(
            isEmpty
                ? []
                : [
                    claudeConnection(),
                    claudeConnection(
                      id: 'g-lee',
                      uid: 'uid-lee',
                      memberId: 'm-lee',
                      clientName: 'ChatGPT',
                      scopes: const ['lists:read', 'lists:write'],
                      lastUsedAgo: const Duration(days: 2),
                    ),
                  ],
          )
          ..emitActivity([
            assistantActivity('a1'),
            assistantActivity(
              'a2',
              tool: 'add_grocery_items',
              ago: const Duration(hours: 3),
            ),
            assistantActivity(
              'a3',
              grantId: 'g-lee',
              memberId: 'm-lee',
              tool: 'tick_grocery_items',
              ago: const Duration(days: 2),
            ),
          ]);
      },
    );
  }

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('assistants-$theme', (tester) async {
      await captureAssistants(
        tester,
        'assistants-$theme',
        brightness: brightness,
        isEmpty: false,
      );
    });

    testWidgets('assistants-empty-$theme', (tester) async {
      await captureAssistants(
        tester,
        'assistants-empty-$theme',
        brightness: brightness,
        isEmpty: true,
      );
    });
  }

  testWidgets('assistants-dark-200-percent-text', (tester) async {
    await captureAssistants(
      tester,
      'assistants-dark-200-percent-text',
      brightness: Brightness.dark,
      isEmpty: false,
      textScale: 2,
    );
  });
}
