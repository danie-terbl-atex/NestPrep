import '../../../shared/async/async_state.dart';
import '../../accounts/model/account.dart';
import '../../subscriptions/model/entitlement.dart';
import 'tour_version.dart';

/// Whether the household shell opens the welcome tour by itself now
/// (welcome-tour ADR-0001) — asked only once the household has loaded and
/// nothing else is moving the person.
///
/// It opens on Today, where every first run lands, for an account (a kid
/// device has none) that has not seen [TourVersion.current], once the
/// entitlement has answered — before that the tour would say the wrong
/// things to a premium household — and the switches have answered or failed
/// to (their defaults then stand), and at most once per shell,
/// so the moment between leaving it and the account write coming back cannot
/// open it twice.
abstract final class WelcomeTourTrigger {
  static bool shouldOpen({
    required bool isOnToday,
    required Account? account,
    required AsyncState<Entitlement> entitlement,
    required bool flagsHaveSettled,
    required bool hasOpened,
  }) =>
      isOnToday &&
      !hasOpened &&
      account != null &&
      !account.hasSeenTour(TourVersion.current) &&
      entitlement is AsyncData<Entitlement> &&
      flagsHaveSettled;
}
