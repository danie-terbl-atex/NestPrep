import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/app_log.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../data/digest_prompt_store.dart';
import '../data/notification_repository.dart';
import '../model/inbox_item.dart';
import '../model/notification_vocabulary.dart';

/// Offers today's digest on the first open of the household's day on this
/// device (notifications ADR-0005). A day with no unread digest is not used
/// up, so a later open can still offer one that has landed since.
final class DigestPromptController extends ChangeNotifier {
  DigestPromptController({
    required this._repository,
    required this._store,
    required this._clock,
    required this.householdId,
    required this.memberId,
  });

  final NotificationRepository _repository;
  final DigestPromptStore _store;
  final HouseholdClock _clock;
  final String householdId;
  final String memberId;

  StreamSubscription<InboxItem?>? _subscription;
  InboxItem? _digest;
  CalendarDate? _shownFor;
  int _openings = 0;
  bool _isDisposed = false;

  InboxItem? get digest => _digest;

  Future<void> opened() async {
    if (memberId.isEmpty) return;
    final today = _clock.today;
    if (_digest != null && _shownFor == today) return;
    final opening = ++_openings;
    _drop();
    if (await _store.lastOffered(householdId, memberId) == today) return;
    if (_isDisposed || opening != _openings) return;
    _subscription = _repository
        .watchItem(householdId, DigestIds.of(memberId, today))
        .listen(
          (item) => _arrived(item, today),
          onError: (Object error) {
            AppLog.failure('digest offer', code: 'watch', error: error);
            _drop();
          },
        );
  }

  void dismiss() => _drop();

  void _arrived(InboxItem? item, CalendarDate today) {
    if (item == null || !item.isUnread) {
      _drop();
      return;
    }
    final isFirst = _digest == null;
    _digest = item;
    _shownFor = today;
    notifyListeners();
    if (isFirst) unawaited(_store.markOffered(householdId, memberId, today));
  }

  void _drop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (_digest == null) return;
    _digest = null;
    _shownFor = null;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
