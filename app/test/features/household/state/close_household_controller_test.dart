import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/state/close_household_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';

/// Closing a household (household ADR-0007): the typed word, one call, a
/// refusal kept for the screen — and which households offer it at all.
void main() {
  late FakeHouseholdDirectory directory;
  late CloseHouseholdController controller;

  setUp(() {
    directory = FakeHouseholdDirectory();
    controller = CloseHouseholdController(
      householdDirectory: directory,
      householdId: Fixtures.householdId,
    );
  });

  tearDown(() => controller.dispose());

  group('the controller', () {
    test('cannot close until the word is typed, in any case', () async {
      expect(controller.canClose, isFalse);
      await controller.close();
      expect(directory.closed, isEmpty);

      controller.typeConfirmation('  close ');
      expect(controller.canClose, isTrue);
      await controller.close();
      expect(directory.closed.single.confirmation, 'CLOSE');
      expect(controller.isClosed, isTrue);
      expect(controller.canClose, isFalse);
    });

    test('a double tap sends once', () async {
      directory.gate = Completer<void>();
      controller.typeConfirmation('CLOSE');
      final first = controller.close();
      final second = controller.close();
      expect(controller.isClosing, isTrue);
      directory.release();
      await Future.wait([first, second]);
      expect(directory.closed, hasLength(1));
    });

    test('a refusal is kept, and the person may try again', () async {
      directory.failWith = const HouseholdFailure(
        HouseholdProblem.otherAdultsRemain,
      );
      controller.typeConfirmation('CLOSE');
      await controller.close();
      expect(
        controller.failure,
        const HouseholdFailure(HouseholdProblem.otherAdultsRemain),
      );
      expect(controller.isClosed, isFalse);
      expect(controller.canClose, isTrue);
    });
  });

  group('who is offered it', () {
    HouseholdView viewOf(Map<String, String> members) => HouseholdView(
      household: Household(
        id: Fixtures.householdId,
        name: 'The Parkers',
        timeZone: 'Africa/Johannesburg',
        members: members,
      ),
      members: const [],
      viewerUid: Fixtures.samUid,
    );

    test('the only adult, alone or with helpers and kids', () {
      expect(viewOf({Fixtures.samUid: 'admin'}).viewerCanClose, isTrue);
      expect(
        viewOf({
          Fixtures.samUid: 'admin',
          Fixtures.thandiUid: 'helper',
          'kid-uid': 'kid',
        }).viewerCanClose,
        isTrue,
      );
    });

    test('not while another parent or admin has joined', () {
      expect(
        viewOf({Fixtures.samUid: 'admin', Fixtures.thandiUid: 'parent'})
            .viewerCanClose,
        isFalse,
      );
      expect(
        viewOf({Fixtures.samUid: 'admin', Fixtures.thandiUid: 'member'})
            .viewerCanClose,
        isFalse,
        reason: 'an old `member` is a parent now (household ADR-0003)',
      );
      expect(
        viewOf({Fixtures.samUid: 'admin', Fixtures.thandiUid: 'admin'})
            .viewerCanClose,
        isFalse,
      );
    });

    test('never for somebody who is not the admin', () {
      final asHelper = HouseholdView(
        household: viewOf({
          Fixtures.samUid: 'admin',
          Fixtures.thandiUid: 'helper',
        }).household,
        members: const [],
        viewerUid: Fixtures.thandiUid,
      );
      expect(asHelper.viewerCanClose, isFalse);
    });
  });
}
