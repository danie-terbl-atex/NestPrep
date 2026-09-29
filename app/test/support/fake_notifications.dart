import 'dart:async';

import 'package:nestprep/features/notifications/data/notification_directory.dart';
import 'package:nestprep/features/notifications/data/notification_repository.dart';
import 'package:nestprep/features/notifications/data/push_gateway.dart';
import 'package:nestprep/features/notifications/data/push_token_repository.dart';
import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/notifications/model/notification_settings.dart';
import 'package:nestprep/features/notifications/model/push_arrival.dart';
import 'package:nestprep/features/notifications/model/push_token.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// A person's inbox and settings held in memory, the way Firestore would hand
/// them back: every listener gets what is there now, then every change —
/// delivered at once rather than on a later microtask. Marks,
/// clears and saves change the state and are recorded, so a test asserts both
/// what the screen shows and what it asked for.
final class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({List<InboxItem> items = const []})
    : _items = [...items];

  List<InboxItem> _items;
  final _settings = <String, NotificationSettings>{};
  // Synchronous, so a repository made in `setUp` answers inside a widget
  // test's own clock rather than on a microtask that clock never runs.
  final _changes = StreamController<void>.broadcast(sync: true);
  AppFailure? _inboxFailure;

  AppFailure? failWritesWith;

  /// Holds every listener on "not yet": the loading state.
  bool isLoading = false;
  final markedRead = <String>[];
  final cleared = <String>[];
  final saved = <NotificationSettings>[];

  List<InboxItem> get items => List.unmodifiable(_items);

  void setItems(List<InboxItem> items) {
    _items = [...items];
    _changes.add(null);
  }

  void setSettings(NotificationSettings settings) {
    _settings[settings.id] = settings;
    _changes.add(null);
  }

  NotificationSettings? settingsOf(String memberId) => _settings[memberId];

  void failInboxWith(AppFailure failure) {
    _inboxFailure = failure;
    _changes.add(null);
  }

  Future<void> close() => _changes.close();

  Stream<T> _live<T>(T Function() read) => Stream<T>.multi((controller) {
    void emit() {
      if (isLoading) return;
      final failure = _inboxFailure;
      if (failure != null) {
        controller.addErrorSync(failure);
      } else {
        controller.addSync(read());
      }
    }

    emit();
    final subscription = _changes.stream.listen((_) => emit());
    // Not handed back: a `first` would wait on it, on a clock a widget test
    // does not run.
    controller.onCancel = () => unawaited(subscription.cancel());
  });

  @override
  Stream<List<InboxItem>> watchInbox(String householdId, String memberId) =>
      _live(() => _items.where((item) => item.memberId == memberId).toList());

  @override
  Stream<int> watchUnreadCount(String householdId, String memberId) => _live(
    () => _items
        .where((item) => item.memberId == memberId && item.isUnread)
        .length,
  );

  @override
  Stream<InboxItem?> watchItem(String householdId, String itemId) =>
      _live(() => _items.where((item) => item.id == itemId).firstOrNull);

  @override
  Future<void> markRead(String householdId, String itemId) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    markedRead.add(itemId);
    setItems([
      for (final item in _items)
        item.id == itemId ? item.copyWith(readAt: DateTime.utc(2026)) : item,
    ]);
  }

  @override
  Future<void> clear(String householdId, String itemId) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    cleared.add(itemId);
    setItems([
      for (final item in _items)
        if (item.id != itemId) item,
    ]);
  }

  @override
  Stream<NotificationSettings?> watchSettings(
    String householdId,
    String memberId,
  ) => _live(() => _settings[memberId]);

  @override
  Future<void> saveSettings(
    String householdId,
    NotificationSettings settings,
  ) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    saved.add(settings);
    setSettings(settings);
  }
}

/// The phone's push service, driven by hand: what the phone would answer, and
/// pushes arriving when the test says.
final class FakePushGateway implements PushGateway {
  FakePushGateway({
    this.current = PushPermission.notAsked,
    this.answer = PushPermission.granted,
    this.phoneToken = 'token-1',
  });

  PushPermission current;
  PushPermission answer;
  String? phoneToken;
  PushArrival? launch;

  int prompts = 0;
  int forgets = 0;
  List<PushChannelSpec> channels = const [];

  final _refreshes = StreamController<String>.broadcast();
  final _foreground = StreamController<PushArrival>.broadcast();
  final _opened = StreamController<PushArrival>.broadcast();

  void rotateToken(String token) {
    phoneToken = token;
    _refreshes.add(token);
  }

  void arriveWhileOpen(PushArrival arrival) => _foreground.add(arrival);
  void tap(PushArrival arrival) => _opened.add(arrival);

  Future<void> close() async {
    await _refreshes.close();
    await _foreground.close();
    await _opened.close();
  }

  @override
  PushPlatform? get platform => PushPlatform.android;

  @override
  Future<PushPermission> permission() async => current;

  @override
  Future<PushPermission> requestPermission() async {
    prompts += 1;
    current = answer;
    return answer;
  }

  @override
  Future<String?> token() async => phoneToken;

  @override
  Stream<String> get tokenRefreshes => _refreshes.stream;

  @override
  Stream<PushArrival> get foregroundArrivals => _foreground.stream;

  @override
  Stream<PushArrival> get openedArrivals => _opened.stream;

  @override
  Future<PushArrival?> launchArrival() async => launch;

  @override
  Future<void> forgetToken() async => forgets += 1;

  @override
  Future<void> prepareChannels(List<PushChannelSpec> channels) async =>
      this.channels = channels;
}

final class FakePushTokenRepository implements PushTokenRepository {
  AppFailure? failWith;
  final registered = <(String, PushToken)>[];

  @override
  Future<void> register(String uid, PushToken token) async {
    final failure = failWith;
    if (failure != null) throw failure;
    registered.add((uid, token));
  }
}

final class FakeNotificationDirectory implements NotificationDirectory {
  FakeNotificationDirectory({this.outcome = TestPushOutcome.sent});

  TestPushOutcome outcome;
  AppFailure? failWith;
  final sentFor = <String>[];

  @override
  Future<TestPushOutcome> sendTestNotification(String householdId) async {
    final failure = failWith;
    if (failure != null) throw failure;
    sentFor.add(householdId);
    return outcome;
  }
}
