import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/product_analytics/state/beta_numbers_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_product_analytics.dart';

void main() {
  late FakeBetaNumbersRepository repository;
  late BetaNumbersController controller;

  setUp(() {
    repository = FakeBetaNumbersRepository(isReader: true);
    controller = BetaNumbersController(
      betaNumbersRepository: repository,
      now: () => DateTime(2026, 10, 1, 9),
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('is loading until the first weeks arrive', () {
    expect(controller.weeks, isA<AsyncLoading<Object>>());
  });

  test('holds the weeks, newest first, as they arrive', () async {
    repository.emitWeeks([
      weekOf('2026-W40', CalendarDate(2026, 9, 28), activeFamilies: 3),
      weekOf('2026-W39', CalendarDate(2026, 9, 21), activeFamilies: 1),
    ]);
    await pumpEventQueue();

    final weeks = controller.weeks;
    expect(weeks, isA<AsyncData<Object>>());
    final data = (weeks as AsyncData).value as List;
    expect(data, hasLength(2));
  });

  test(
    'shows a refusal as a failure, which is what a non-reader sees',
    () async {
      repository.failWeeksWith(const PermissionDeniedFailure());
      await pumpEventQueue();

      final weeks = controller.weeks;
      expect(weeks, isA<AsyncFailure<Object>>());
      expect((weeks as AsyncFailure).failure, isA<PermissionDeniedFailure>());
    },
  );

  test('wraps an error it does not know, rather than losing it', () async {
    repository.failWeeksWith(StateError('boom'));
    await pumpEventQueue();

    expect((controller.weeks as AsyncFailure).failure, isA<UnknownFailure>());
  });

  test('starts again from loading on retry, and recovers', () async {
    repository.failWeeksWith(const UnavailableFailure());
    await pumpEventQueue();

    await controller.retry();
    expect(controller.weeks, isA<AsyncLoading<Object>>());
    repository.emitWeeks(const []);
    await pumpEventQueue();

    expect(controller.weeks, isA<AsyncData<Object>>());
  });

  test('knows what today is on this phone', () {
    expect(controller.today, CalendarDate(2026, 10, 1));
  });
}
