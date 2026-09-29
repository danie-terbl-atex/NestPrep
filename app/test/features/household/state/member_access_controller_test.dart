import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/state/member_access_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_household.dart';

/// The access editor's draft: what a parent is choosing, before it is saved
/// through `setMemberAccess` (household ADR-0003).
void main() {
  late FakeHouseholdDirectory directory;
  late MemberAccessController controller;

  setUp(() {
    directory = FakeHouseholdDirectory();
    controller = MemberAccessController(
      householdDirectory: directory,
      householdId: 'h1',
      memberId: 'm-thandi',
      startingFrom: AccessDefaults.helper,
    );
  });

  tearDown(() => controller.dispose());

  test('starts from what the household holds, with nothing to save', () {
    expect(controller.draft, AccessDefaults.helper);
    expect(controller.hasChangesFrom(AccessDefaults.helper), isFalse);
  });

  test('changing an area makes something to save', () {
    controller.setLevel(HouseholdArea.documents, AccessLevel.view);
    expect(controller.draft.levelIn(HouseholdArea.documents), AccessLevel.view);
    expect(controller.hasChangesFrom(AccessDefaults.helper), isTrue);
  });

  test('a preset replaces the whole draft', () {
    final nothing = AccessGrant.uniform(AccessLevel.none);
    controller.applyPreset(nothing);
    expect(controller.draft, nothing);
  });

  test('saving sends the whole grant, and says it was saved', () async {
    controller.setLevel(HouseholdArea.documents, AccessLevel.view);
    expect(await controller.save(), isTrue);

    final sent = directory.accessSet.single;
    expect(sent.memberId, 'm-thandi');
    expect(sent.access.levelIn(HouseholdArea.documents), AccessLevel.view);
    expect(controller.justSaved, isTrue);
    expect(
      controller.hasChangesFrom(AccessDefaults.helper),
      isFalse,
      reason:
          'the listener has not caught up yet; the button must not '
          'offer to save the same thing again meanwhile',
    );
  });

  test(
    'a refusal is kept for the banner, and nothing is marked saved',
    () async {
      directory.failWith = const HouseholdFailure(HouseholdProblem.notAnAdmin);
      controller.setLevel(HouseholdArea.documents, AccessLevel.view);

      expect(await controller.save(), isFalse);
      expect(controller.actionFailure, isA<HouseholdFailure>());
      expect(controller.justSaved, isFalse);
    },
  );

  test('a double tap sends one save', () async {
    directory.gate = Completer<void>();
    controller.setLevel(HouseholdArea.documents, AccessLevel.view);
    final first = controller.save();
    expect(await controller.save(), isFalse);
    directory.release();
    await first;
    expect(directory.accessSet, hasLength(1));
  });
}
