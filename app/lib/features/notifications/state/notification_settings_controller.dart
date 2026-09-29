import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/member.dart';
import '../data/notification_directory.dart';
import '../data/notification_repository.dart';
import '../model/notification_settings.dart';
import '../model/notification_vocabulary.dart';
import '../model/push_arrival.dart';
import 'push_registrar.dart';
import 'turn_on_notifications.dart';

/// The notification settings screen (notifications ADR-0003): the person's own
/// choices, live, and — for family — each child's digest switch. Every change
/// is one write of the whole document, which the rules check field by field;
/// a refusal is held for the screen to put into words.
final class NotificationSettingsController extends ChangeNotifier
    with ActionFailureHolder {
  NotificationSettingsController({
    required this._repository,
    required this._directory,
    required this._registrar,
    required this.owner,
    required this._kids,
  }) {
    _subscribe();
  }

  final NotificationRepository _repository;
  final NotificationDirectory _directory;
  final PushRegistrar _registrar;
  final NotificationsOwner owner;
  final List<Member> _kids;

  final _subscriptions = <StreamSubscription<Object?>>[];
  final _kidSettings = <String, NotificationSettings>{};
  AsyncState<NotificationSettings> _settings = const AsyncLoading();

  /// The person's last change while any write is still on its way. Two
  /// switches flipped faster than the listener answers would otherwise each
  /// start from the document as it was, and the second would put the first
  /// back. It is never a second copy of the server's state: it is cleared by
  /// the listener's first answer once the writes have gone, or by a refusal,
  /// and the listener is the truth again (`FE-07`).
  NotificationSettings? _pending;
  int _writing = 0;

  /// A listener's answer or a write's end can arrive after the screen has
  /// gone; it then tells nobody.
  bool _isDisposed = false;
  TestPushOutcome? _testOutcome;
  bool _isSendingTest = false;

  /// What the screen shows: the person's own last change while it is still
  /// on its way, otherwise the listener's latest.
  AsyncState<NotificationSettings> get settings {
    final pending = _pending;
    return pending == null ? _settings : AsyncData(pending);
  }

  /// The children family may silence, only for family (ADR-0003).
  List<Member> get kids => owner.isFamily ? _kids : const [];

  NotificationSettings kidSettings(String kidId) =>
      _kidSettings[kidId] ?? NotificationSettings.unchosen(kidId);

  TestPushOutcome? get testOutcome => _testOutcome;
  bool get isSendingTest => _isSendingTest;

  Future<void> retry() async {
    await _cancel();
    _settings = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  Future<PushPermission> turnOn() => turnOnNotifications(
    registrar: _registrar,
    repository: _repository,
    owner: owner,
  );

  Future<void> setDigest({bool? enabled, int? minute}) => _change(
    (current) => current.copyWith(
      digest: current.digest.copyWith(
        enabled: enabled ?? current.digest.enabled,
        minute: minute == null ? current.digest.minute : _onTheStep(minute),
      ),
    ),
  );

  Future<void> setCategory(SwitchableCategory category, bool on) =>
      _change((current) => current.withCategory(category, on));

  Future<void> setQuietHours({bool? enabled, int? start, int? end}) => _change(
    (current) => current.copyWith(
      quietHours: current.quietHours.copyWith(
        enabled: enabled ?? current.quietHours.enabled,
        startMinute: start ?? current.quietHours.startMinute,
        endMinute: end ?? current.quietHours.endMinute,
      ),
    ),
  );

  Future<void> setKidDigest(String kidId, bool enabled) {
    final current = kidSettings(kidId);
    return runAction(
      () => _repository.saveSettings(
        owner.householdId,
        current.copyWith(
          digest: current.digest.copyWith(enabled: enabled),
          updatedBy: owner.memberId,
        ),
      ),
    );
  }

  Future<void> sendTest() async {
    if (_isSendingTest) return;
    _isSendingTest = true;
    _testOutcome = null;
    notifyListeners();
    try {
      await runAction(() async {
        _testOutcome = await _directory.sendTestNotification(owner.householdId);
      });
    } finally {
      _isSendingTest = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> _change(
    NotificationSettings Function(NotificationSettings current) change,
  ) async {
    final current =
        _pending ??
        switch (_settings) {
          AsyncData(:final value) => value,
          _ => null,
        };
    if (current == null) return;
    final next = change(current).copyWith(updatedBy: owner.memberId);
    _pending = next;
    _writing += 1;
    notifyListeners();
    try {
      await runAction(() => _repository.saveSettings(owner.householdId, next));
    } finally {
      _writing -= 1;
      // Refused: the listener's document is the truth again at once.
      // Otherwise the change stands until the listener answers with it.
      if (actionFailure != null) _pending = null;
      if (!_isDisposed) notifyListeners();
    }
  }

  static int _onTheStep(int minute) =>
      minute - (minute % DigestTimes.stepMinutes);

  void _subscribe() {
    _listen(_repository.watchSettings(owner.householdId, owner.memberId), (
      value,
    ) {
      _settings = AsyncData(
        value ?? NotificationSettings.unchosen(owner.memberId),
      );
      if (_writing == 0) _pending = null;
    });
    for (final kid in kids) {
      _listen(_repository.watchSettings(owner.householdId, kid.id), (value) {
        if (value == null) {
          _kidSettings.remove(kid.id);
        } else {
          _kidSettings[kid.id] = value;
        }
      });
    }
  }

  void _listen<T>(Stream<T> stream, void Function(T value) onValue) {
    _subscriptions.add(
      stream.listen(
        (value) {
          if (_isDisposed) return;
          onValue(value);
          notifyListeners();
        },
        onError: (Object error) {
          if (_isDisposed) return;
          _settings = AsyncFailure(
            error is AppFailure ? error : UnknownFailure(error),
          );
          notifyListeners();
        },
      ),
    );
  }

  Future<void> _cancel() async {
    final open = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in open) {
      await subscription.cancel();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_cancel());
    super.dispose();
  }
}
