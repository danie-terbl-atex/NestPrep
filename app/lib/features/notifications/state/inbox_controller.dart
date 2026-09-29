import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/notification_repository.dart';
import '../model/inbox_item.dart';

/// A person's inbox (notifications ADR-0001): the live list, and the three
/// things they may do to it — mark one read, mark all read, clear one. It
/// holds the listener's latest emission and nothing the listener does not
/// (foundation ADR-0006).
final class InboxController extends ChangeNotifier with ActionFailureHolder {
  InboxController({
    required this._repository,
    required this.householdId,
    required this.memberId,
  }) {
    _subscribe();
  }

  final NotificationRepository _repository;
  final String householdId;
  final String memberId;

  StreamSubscription<List<InboxItem>>? _subscription;
  AsyncState<List<InboxItem>> _items = const AsyncLoading();

  AsyncState<List<InboxItem>> get items => _items;

  bool get hasUnread => switch (_items) {
    AsyncData(:final value) => value.any((item) => item.isUnread),
    _ => false,
  };

  Future<void> retry() async {
    await _subscription?.cancel();
    _items = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  Future<void> markRead(InboxItem item) async {
    if (!item.isUnread) return;
    await runAction(() => _repository.markRead(householdId, item.id));
  }

  Future<void> markAllRead() async {
    final unread = switch (_items) {
      AsyncData(:final value) => value.where((item) => item.isUnread),
      _ => const <InboxItem>[],
    };
    await runAction(() async {
      for (final item in unread) {
        await _repository.markRead(householdId, item.id);
      }
    });
  }

  Future<void> clear(InboxItem item) =>
      runAction(() => _repository.clear(householdId, item.id));

  void _subscribe() {
    _subscription = _repository
        .watchInbox(householdId, memberId)
        .listen(
          (items) {
            _items = AsyncData(items);
            notifyListeners();
          },
          onError: (Object error) {
            _items = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
