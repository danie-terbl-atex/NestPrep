import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/data/household_directory.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/ui/invite_sheet.dart';
import 'package:nestprep/features/household/ui/member_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/format/nest_dates.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';

/// The two sheets the household screen opens: the one that makes a person, and
/// the one that hands out a code. Both were at zero.
/// Friday 18 September 2026, where the household lives — what bounds the
/// birthday picker (foundation ADR-0007).
final _today = CalendarDate.parse('2026-09-18');

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

    Future<void> open(
      WidgetTester tester, {
      bool editing = false,
      Member? existing,
    }) async {
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
                today: _today,
                existing: existing ?? (editing ? Fixtures.kid : null),
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
      // The role picker says what each role means, so the save sits below
      // the fold of a phone-sized sheet (the lesson on taps below the fold).
      await tester.ensureVisible(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
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

    testWidgets('a new person starts with no birthday, which is an answer', (
      tester,
    ) async {
      await open(tester);

      expect(find.text(AppCopy.householdMemberBirthday), findsOneWidget);
      expect(
        find.text(AppCopy.householdBirthdayNone),
        findsOneWidget,
        reason: 'not knowing is the common case and has to be sayable',
      );

      await tester.enterText(
        fieldLabelled(AppCopy.householdMemberName),
        'Gogo',
      );
      await tester.pumpAndSettle();
      // The role picker says what each role means, so the save sits below
      // the fold of a phone-sized sheet (the lesson on taps below the fold).
      await tester.ensureVisible(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
      await tester.pumpAndSettle();

      expect(result?.birthday, isNull);
    });

    testWidgets('a day and a month with no year comes back as one', (
      tester,
    ) async {
      await open(tester);

      await tester.enterText(
        fieldLabelled(AppCopy.householdMemberName),
        'Gogo',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppCopy.householdBirthdayNoYear));
      await tester.pumpAndSettle();

      expect(
        find.text(AppCopy.householdBirthdayYearUnknown),
        findsOneWidget,
        reason: 'the row says which half of the birthday is missing',
      );

      // The role picker says what each role means, so the save sits below
      // the fold of a phone-sized sheet (the lesson on taps below the fold).
      await tester.ensureVisible(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
      await tester.pumpAndSettle();

      expect(result?.birthday?.hasYear, isFalse);
      expect(result?.birthday?.iso, '--09-18');
    });

    testWidgets('editing opens on the birthday the person already has', (
      tester,
    ) async {
      await open(
        tester,
        existing: Fixtures.kid.copyWith(
          birthday: Birthday(year: 2017, month: 3, day: 4),
        ),
      );

      expect(
        find.text(NestDates.dayOfYear(month: 3, day: 4, year: 2017)),
        findsOneWidget,
      );

      // The role picker says what each role means, so the save sits below
      // the fold of a phone-sized sheet (the lesson on taps below the fold).
      await tester.ensureVisible(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
      await tester.pumpAndSettle();

      expect(result?.birthday, Birthday(year: 2017, month: 3, day: 4));
    });

    testWidgets('and a birthday can be taken away again', (tester) async {
      await open(
        tester,
        existing: Fixtures.kid.copyWith(
          birthday: Birthday(year: 2017, month: 3, day: 4),
        ),
      );

      await tester.tap(find.text(AppCopy.householdBirthdayNone));
      await tester.pumpAndSettle();
      // The role picker says what each role means, so the save sits below
      // the fold of a phone-sized sheet (the lesson on taps below the fold).
      await tester.ensureVisible(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
      await tester.pumpAndSettle();

      expect(
        result?.birthday,
        isNull,
        reason: 'a birthday set by mistake has to be removable',
      );
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

      var shared = 0;
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
              onShare: () => shared += 1,
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('ABCD2345'), findsOneWidget);
      expect(find.text(Fixtures.kid.displayName), findsOneWidget);

      // The share sheet is the first way out (household ADR-0003).
      await tester.tap(find.widgetWithText(NestButton, AccessCopy.inviteShare));
      expect(shared, 1);

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
