import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/guardian_consent.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/state/invite_step_controller.dart';
import 'package:nestprep/features/household/ui/invite_person_sheet.dart';
import 'package:nestprep/features/household/ui/member_sheet.dart';
import 'package:nestprep/features/legal/model/legal_versions.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../support/fake_household.dart';
import '../../support/fake_invite_sharer.dart';
import '../../support/household_fixtures.dart';
import '../../support/pump_kit.dart';

/// A parent's consent when a child's profile is made (accounts ADR-0005):
/// asked in both sheets that can make a kid, recorded against the adult who
/// gave it and the privacy policy's version, and never asked of an adult.
void main() {
  group('the member sheet', () {
    MemberDraft? result;

    Future<void> open(WidgetTester tester, {Member? existing}) async {
      result = null;
      await pumpKit(
        tester,
        Builder(
          builder: (context) => NestButton(
            label: 'open',
            onPressed: () async => result = await showMemberSheet(
              context: context,
              today: CalendarDate.parse('2026-09-29'),
              existing: existing,
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> chooseKid(WidgetTester tester) async {
      final kid = find.text(AccessCopy.roleName(MemberRole.kid));
      await tester.ensureVisible(kid);
      await tester.tap(kid);
      await tester.pumpAndSettle();
    }

    NestButton save(WidgetTester tester) => tester.widget<NestButton>(
      find.widgetWithText(NestButton, AppCopy.householdSave),
    );

    Future<void> press(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('a new kid cannot be saved until a parent consents', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(find.byType(TextField).first, 'Lwazi');
      await tester.pump();
      expect(find.text(LegalCopy.guardianConsentLabel), findsNothing);

      await chooseKid(tester);
      expect(find.text(LegalCopy.guardianConsentLabel), findsOneWidget);
      expect(save(tester).onPressed, isNull);

      await press(tester, find.text(LegalCopy.guardianConsentLabel));
      expect(save(tester).onPressed, isNotNull);
      await press(
        tester,
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      expect(result?.role, MemberRole.kid);
      expect(result?.guardianConsent, isTrue);
    });

    testWidgets('an adult is never asked', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField).first, 'Gogo');
      await tester.pump();
      await press(
        tester,
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      expect(result?.role, MemberRole.parent);
      expect(result?.guardianConsent, isFalse);
    });

    testWidgets('an adult moved to kid is asked', (tester) async {
      await open(tester, existing: Fixtures.thandi.copyWith(claimedBy: null));
      await chooseKid(tester);
      expect(find.text(LegalCopy.guardianConsentLabel), findsOneWidget);
    });

    testWidgets('a kid made before consent is not asked at every edit', (
      tester,
    ) async {
      await open(tester, existing: Fixtures.kid);
      expect(find.text(LegalCopy.guardianConsentLabel), findsNothing);
      expect(save(tester).onPressed, isNotNull);
    });
  });

  group('the invite sheet', () {
    testWidgets('inviting a kid asks for consent before it sends', (
      tester,
    ) async {
      InviteDraft? draft;
      await pumpKit(
        tester,
        Builder(
          builder: (context) => NestButton(
            label: 'open',
            onPressed: () async => draft = await showInvitePersonSheet(
              context: context,
              suggestedRole: MemberRole.kid,
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Lwazi');
      await tester.pump();

      final send = find.widgetWithText(NestButton, AccessCopy.inviteSend);
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      expect(tester.widget<NestButton>(send).onPressed, isNull);

      await tester.ensureVisible(find.text(LegalCopy.guardianConsentLabel));
      await tester.tap(find.text(LegalCopy.guardianConsentLabel));
      await tester.pumpAndSettle();
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(draft?.guardianConsent, isTrue);
    });
  });

  group('what is written', () {
    late FakeHouseholdRepository repository;

    setUp(() => repository = FakeHouseholdRepository());
    tearDown(() => repository.close());

    test('a kid carries the consent of the adult who added them', () async {
      final controller = HouseholdController(
        householdRepository: repository,
        householdDirectory: FakeHouseholdDirectory(),
        householdId: Fixtures.householdId,
        viewerUid: Fixtures.samUid,
      );
      addTearDown(controller.dispose);
      repository
        ..emitHousehold(Fixtures.household())
        ..emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
      await pumpEventQueue();

      await controller.addMember(
        displayName: 'Lwazi',
        color: MemberColor.teal,
        role: MemberRole.kid,
        guardianConsent: true,
      );
      expect(
        repository.added.single.guardianConsent,
        const GuardianConsent(
          byMemberId: Fixtures.samMemberId,
          version: LegalVersions.privacy,
        ),
      );

      await controller.addMember(
        displayName: 'Gogo',
        color: MemberColor.teal,
        role: MemberRole.parent,
        guardianConsent: true,
      );
      expect(
        repository.added.last.guardianConsent,
        isNull,
        reason: 'only a kid carries one',
      );

      await controller.updateMember(
        memberId: Fixtures.kidMemberId,
        displayName: 'Kid',
        color: MemberColor.teal,
        role: MemberRole.kid,
      );
      expect(repository.updated.single.guardianConsent, isNull);
    });

    test('inviting a kid records the inviting adult', () async {
      final controller = InviteStepController(
        householdRepository: repository,
        householdDirectory: FakeHouseholdDirectory(),
        inviteSharer: FakeInviteSharer(appLink: Uri.parse('https://x.test')),
        householdId: 'h1',
        householdName: 'The Parkers',
        coloursInUse: const [],
        viewerMemberId: Fixtures.samMemberId,
      );
      addTearDown(controller.dispose);
      await controller.invite(
        displayName: 'Lwazi',
        role: MemberRole.kid,
        guardianConsent: true,
      );
      expect(
        repository.added.single.guardianConsent?.byMemberId,
        Fixtures.samMemberId,
      );
    });
  });
}
