import 'dart:async';

import '../features/accounts/model/session.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/kid_accounts/ui/kid_home_screen.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/model/notification_vocabulary.dart';
import '../features/notifications/model/push_arrival.dart';
import '../shared/async/async_state.dart';
import '../shared/log/best_effort.dart';
import 'notifications_route.dart';

/// What happens when somebody taps a notification (notifications ADR-0001):
/// wait for the session to be there — a tap can be what started the app —
/// move to the notification's household if it is another one, mark it read,
/// and land where its target says. A kid's tablet has one screen, so it lands
/// there.
///
/// It navigates through [go] and [push] rather than a router it owns, so a
/// test can watch where it went.
final class PushTapRouter {
  PushTapRouter({
    required this._session,
    required this._repository,
    required this._go,
    required this._push,
    this._patience = const Duration(seconds: 10),
  });

  final SessionController _session;
  final NotificationRepository _repository;
  final void Function(String location) _go;
  final void Function(String location) _push;
  final Duration _patience;

  Future<void> open(PushArrival arrival) async {
    if (!await _until(_isSignedIn)) return;
    if (_session.kidIdentity != null) {
      _go(KidHomeScreen.path);
      return;
    }
    if (_session.activeHouseholdId != arrival.householdId) {
      await _session.switchHousehold(arrival.householdId);
      if (!await _until(
        () => _session.activeHouseholdId == arrival.householdId,
      )) {
        return;
      }
    }
    // An opened digest marks itself read; anything that lands elsewhere is
    // read by being tapped.
    if (arrival.target != NotificationTarget.inboxItem) {
      unawaited(
        bestEffort(
          'inbox item',
          code: 'mark read',
          run: () => _repository.markRead(arrival.householdId, arrival.inboxId),
        ),
      );
    }
    _push(
      NotificationsRoute.targetPath(
        householdId: arrival.householdId,
        inboxId: arrival.inboxId,
        target: arrival.target,
        targetId: arrival.targetId,
      ),
    );
  }

  bool _isSignedIn() => switch (_session.session) {
    AsyncData(value: SignedIn() || KidSignedIn()) => true,
    _ => false,
  };

  /// Waits, bounded, for the session to say yes. A household that never comes
  /// — the account left it — leaves the person where they are.
  Future<bool> _until(bool Function() isReady) async {
    if (isReady()) return true;
    final done = Completer<bool>();
    void check() {
      if (isReady() && !done.isCompleted) done.complete(true);
    }

    _session.addListener(check);
    final timer = Timer(_patience, () {
      if (!done.isCompleted) done.complete(false);
    });
    try {
      return await done.future;
    } finally {
      timer.cancel();
      _session.removeListener(check);
    }
  }
}
