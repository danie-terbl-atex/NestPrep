import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/data/household_directory.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/ui/invite_sheet.dart';
import 'package:nestprep/features/household/ui/member_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';

/// The two sheets the household screen opens: the one that makes a person, and
/// the one that hands out a code. Both were at zero.
void main() {
  Finder fieldLabelled(String label) => find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(NestTextField),
    ),
    matching: find.byType(TextField),
  );

  group('the member sheet', () {
    late MemberDraft? result;
    late bool returned;

    Future<void> open(WidgetTester tester, {bool editing = false}) async {
      result = null;
      returned = false;
      await pumpKit(
        tester,
        Builder(
          builder: (context) => NestButton(
            label: 'open',
            onPressed: () async {
              result = await showMemberSheet(
                context: context,
                existing: editing ? Fixtures.kid : null,
              );
              returned = true;
            },
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a new person cannot be saved without a name', (tester) async {
      await open(tester);

      expect(find.text(AppCopy.householdAddMember), findsWidgets);
      final save = tester.widget<NestButton>(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      expect(
        save.onPressed,
        isNull,
        reason: 'a profile with no name is not a person',
      );
    });

    testWidgets('a name, a colour and a role come back as one draft', (
      tester,
    ) async {
      await open(tester);

      await tester.enterText(
        fieldLabelled(AppCopy.householdMemberName),
        '  Gogo  ',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppCopy.roleName(MemberRole.helper.name)));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(
        result?.displayName,
        'Gogo',
        reason: 'what somebody typed is trimmed, not stored with its spaces',
      );
      expect(result?.role, MemberRole.helper);
    });

    testWidgets('editing opens on the person it was given', (tester) async {
      await open(tester, editing: true);

      expect(find.text(AppCopy.householdEditMember), findsWidgets);
      expect(find.text(Fixtures.kid.displayName), findsOneWidget);
    });

    testWidgets('closing without saving comes back with nothing', (
      tester,
    ) async {
      await open(tester);
      Navigator.of(tester.element(find.byType(NestTextField))).pop();
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(result, isNull, reason: 'no draft means no write');
    });
  });

  group('the invite sheet', () {
    testWidgets('shows the code, and copies it to the clipboard', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<Object?, Object?>)['text']! as String,
            );
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpKit(
        tester,
        Builder(
          builder: (context) => NestButton(
            label: 'open',
            onPressed: () => showInviteSheet(
              context: context,
              member: Fixtures.kid,
              invite: InviteCode(
                code: 'ABCD2345',
                expiresAt: DateTime.utc(2026, 9, 25),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('ABCD2345'), findsOneWidget);
      expect(find.text(Fixtures.kid.displayName), findsOneWidget);

      await tester.tap(
        find.widgetWithText(NestButton, AppCopy.householdCopyCode),
      );
      await tester.pumpAndSettle();

      expect(copied, ['ABCD2345']);
      expect(
        find.text(AppCopy.householdCodeCopied),
        findsOneWidget,
        reason: 'copying silently leaves somebody tapping it again',
      );
    });
  });
}
