import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/ui/member_choice_sheet.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';

/// Picking one member out of a few.
///
/// It was written for "mark done for…" and left at zero covered lines, because
/// the common case — one unclaimed assignee — never opens it. The uncommon case
/// is the one nobody exercises by hand.
void main() {
  late Member? chosen;
  late bool answered;

  Future<void> open(WidgetTester tester, List<Member> members) async {
    chosen = null;
    answered = false;
    await pumpKit(
      tester,
      Builder(
        builder: (context) => NestButton(
          label: 'open',
          onPressed: () async {
            chosen = await showMemberChoiceSheet(
              context: context,
              title: 'Mark done for',
              members: members,
            );
            answered = true;
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers everybody it was given, by name', (tester) async {
    await open(tester, [Fixtures.kid, Fixtures.thandi]);

    expect(find.text(Fixtures.kid.displayName), findsOneWidget);
    expect(find.text(Fixtures.thandi.displayName), findsOneWidget);
  });

  testWidgets('and comes back with the one that was tapped', (tester) async {
    await open(tester, [Fixtures.kid, Fixtures.thandi]);

    await tester.tap(find.text(Fixtures.thandi.displayName));
    await tester.pumpAndSettle();

    expect(answered, isTrue);
    expect(chosen?.id, Fixtures.thandiMemberId);
  });

  testWidgets('closing without choosing comes back with nobody', (
    tester,
  ) async {
    await open(tester, [Fixtures.kid, Fixtures.thandi]);

    Navigator.of(tester.element(find.byType(NestListRow).first)).pop();
    await tester.pumpAndSettle();

    expect(answered, isTrue);
    expect(
      chosen,
      isNull,
      reason: 'dismissing is an answer, and the answer is nobody',
    );
  });

  testWidgets('each row shows the person, not just their colour', (
    tester,
  ) async {
    await open(tester, [Fixtures.kid]);

    // `FE-13`: colour is never the only signal saying who a thing is for.
    expect(find.byType(NestAvatar), findsOneWidget);
    expect(find.text(Fixtures.kid.displayName), findsOneWidget);
  });
}
