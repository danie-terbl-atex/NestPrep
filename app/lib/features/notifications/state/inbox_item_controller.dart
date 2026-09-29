import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../data/notification_repository.dart';
import '../model/inbox_item.dart';

/// One notification, opened — a digest in full (notifications ADR-0002).
/// Opening it is reading it: the first time it arrives unread it is marked
/// read, once. `AsyncData(null)` is a notification that has been cleared.
final class InboxItemController extends ChangeNotifier {
  InboxItemController({
    required this._repository,
    required this.householdId,
    required this.itemId,
  }) {
    _subscribe();
  }

  final NotificationRepository _repository;
  final String householdId;
  final String itemId;

  StreamSubscription<InboxItem?>? _subscription;
  AsyncState<InboxItem?> _item = const AsyncLoading();
  bool _markedRead = false;

  AsyncState<InboxItem?> get item => _item;

  Future<void> retry() async {
    await _subscription?.cancel();
    _item = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _repository
        .watchItem(householdId, itemId)
        .listen(
          (item) {
            _item = AsyncData(item);
            notifyListeners();
            if (item != null && item.isUnread) _markRead();
          },
          onError: (Object error) {
            _item = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  // Read is a nicety, not the point of opening it: a write that fails leaves
  // the dot on, and the log says why (`ENG-10`).
  void _markRead() {
    if (_markedRead) return;
    _markedRead = true;
    unawaited(
      bestEffort(
        'inbox item',
        code: 'mark read',
        run: () => _repository.markRead(householdId, itemId),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
