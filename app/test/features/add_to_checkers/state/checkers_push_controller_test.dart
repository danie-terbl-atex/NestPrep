import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_state.dart';
import 'package:nestprep/features/add_to_checkers/state/cart_push_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeCheckersDirectory directory;
  late CartPushController controller;

  setUp(() {
    directory = FakeCheckersDirectory();
    controller = CartPushController(
      directory: directory,
      householdId: Fixtures.householdId,
    );
  });

  tearDown(() => controller.dispose());

  test('the phone names the items; the answer is the result', () async {
    directory.pushResult = const CartPushResult(
      added: [],
      skipped: [
        CartSkippedLine(itemId: 'i2', reason: CartSkipReason.weighedItem),
      ],
      cartItemCount: 3,
      cartTotal: Money(9000),
    );
    await controller.push(['i1', 'i2']);
    expect(directory.pushes.single.itemIds, ['i1', 'i2']);
    expect(directory.pushes.single.householdId, Fixtures.householdId);
    expect(controller.state, isA<CartPushed>());
  });

  test(
    'a link that ran out asks for linking, then retry pushes the same',
    () async {
      directory.pushFailures.add(
        const CheckersFailure(CheckersProblem.linkExpired),
      );
      await controller.push(['i1']);
      expect(controller.state, isA<CartPushNeedsLink>());

      await controller.retry();
      expect(directory.pushes, hasLength(2));
      expect(directory.pushes.last.itemIds, ['i1']);
      expect(controller.state, isA<CartPushed>());
    },
  );

  test('any other refusal is a failure with a retry', () async {
    directory.pushFailures.add(
      const CheckersFailure(CheckersProblem.checkersDown),
    );
    await controller.push(['i1']);
    expect(
      controller.state,
      isA<CartPushFailed>().having(
        (state) => state.failure,
        'failure',
        isA<CheckersFailure>(),
      ),
    );
  });

  test('nothing to push asks nobody', () async {
    await controller.push(const []);
    expect(directory.pushes, isEmpty);
    expect(controller.state, isA<CartPushIdle>());
  });
}
