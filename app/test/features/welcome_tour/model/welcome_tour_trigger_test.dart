import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/seen_tour.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/welcome_tour/model/tour_version.dart';
import 'package:nestprep/features/welcome_tour/model/welcome_tour_trigger.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// When the shell opens the welcome tour by itself (welcome-tour ADR-0001).
void main() {
  const newcomer = Account(id: 'uid-sam', displayName: 'Sam');
  const answered = AsyncData(Entitlement.free);

  bool opens({
    bool isOnToday = true,
    Account? account = newcomer,
    AsyncState<Entitlement> entitlement = answered,
    bool flagsHaveSettled = true,
    bool hasOpened = false,
  }) => WelcomeTourTrigger.shouldOpen(
    isOnToday: isOnToday,
    account: account,
    entitlement: entitlement,
    flagsHaveSettled: flagsHaveSettled,
    hasOpened: hasOpened,
  );

  test('opens for a newcomer on Today once everything has answered', () {
    expect(opens(), isTrue);
  });

  test('waits for the entitlement, so a premium household never sees the '
      'free tour while it loads', () {
    expect(opens(entitlement: const AsyncLoading()), isFalse);
    expect(
      opens(entitlement: const AsyncFailure(UnknownFailure('offline'))),
      isFalse,
    );
  });

  test('waits for the switches', () {
    expect(opens(flagsHaveSettled: false), isFalse);
  });

  test('opens on Today only, never over another place', () {
    expect(opens(isOnToday: false), isFalse);
  });

  test('never for a kid device, which has no account', () {
    expect(opens(account: null), isFalse);
  });

  test('not again for somebody who has seen this version or a later one', () {
    const seen = SeenTour(version: TourVersion.current);
    expect(opens(account: newcomer.copyWith(tour: seen)), isFalse);
    expect(
      opens(
        account: newcomer.copyWith(
          tour: const SeenTour(version: TourVersion.current + 1),
        ),
      ),
      isFalse,
    );
  });

  test('again for somebody who saw an older version', () {
    expect(
      opens(
        account: newcomer.copyWith(
          tour: const SeenTour(version: TourVersion.current - 1),
        ),
      ),
      isTrue,
    );
  });

  test('at most once per shell', () {
    expect(opens(hasOpened: true), isFalse);
  });
}
