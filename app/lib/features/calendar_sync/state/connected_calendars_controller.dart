import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/links/external_link_opener.dart';
import '../../../shared/state/action_failure.dart';
import '../data/calendar_sync_directory.dart';
import '../data/calendar_sync_repository.dart';
import '../model/calendar_connection.dart';
import '../model/calendar_feed_link.dart';
import '../model/calendar_provider.dart';
import '../model/provider_availability.dart';

/// The connected calendars screen's controller (calendar ADR-0003): the
/// household's connections and feed link as their listeners last saw them,
/// which providers this deployment can connect, and the actions — each one a
/// Function call whose refusal is held for the screen to put into words.
///
/// It holds nothing the listeners do not (`FE-07`): a connection appears here
/// because the Function wrote it, not because this controller added it.
final class ConnectedCalendarsController extends ChangeNotifier
    with ActionFailureHolder {
  ConnectedCalendarsController({
    required CalendarSyncRepository calendarSyncRepository,
    required CalendarSyncDirectory calendarSyncDirectory,
    required ExternalLinkOpener linkOpener,
    required this.householdId,
    required this.viewerUid,
    required this.isAdmin,
    this.canConnect = true,
    DateTime Function()? now,
  }) : _repository = calendarSyncRepository,
       _directory = calendarSyncDirectory,
       _opener = linkOpener,
       _now = now ?? DateTime.now {
    _listen();
    unawaited(_loadAvailability());
  }

  final CalendarSyncRepository _repository;
  final CalendarSyncDirectory _directory;
  final ExternalLinkOpener _opener;
  final DateTime Function() _now;
  final String householdId;
  final String viewerUid;
  final bool isAdmin;

  /// Whether the household's `calendar` grant lets this viewer bring a
  /// calendar into the family week — `edit` (household ADR-0003). With `view`
  /// they see what is connected and the feed link, and connect nothing; the
  /// Functions refuse it either way.
  final bool canConnect;

  StreamSubscription<List<CalendarConnection>>? _connectionSubscription;
  StreamSubscription<CalendarFeedLink?>? _feedSubscription;

  AsyncState<List<CalendarConnection>> _connections = const AsyncLoading();
  AsyncState<ProviderAvailability> _availability = const AsyncLoading();
  CalendarFeedLink? _feed;
  final _busy = <String>{};
  bool _isConnecting = false;
  bool _isSharingFeed = false;
  bool _awaitingBrowser = false;
  int? _connectionsWhenBrowserOpened;

  AsyncState<List<CalendarConnection>> get connections => _connections;
  AsyncState<ProviderAvailability> get availability => _availability;
  CalendarFeedLink? get feed => _feed;
  bool get isConnecting => _isConnecting;
  bool get isSharingFeed => _isSharingFeed;

  /// The browser is open on a provider's consent page and nothing has come
  /// back yet — the screen says where to finish.
  bool get isAwaitingBrowser => _awaitingBrowser;

  bool isBusy(CalendarConnection connection) => _busy.contains(connection.id);

  /// How long ago the connection last synced, or null before its first sync.
  Duration? sinceLastSync(CalendarConnection connection) {
    final at = connection.lastSyncedAt;
    if (at == null) return null;
    final age = _now().toUtc().difference(at);
    return age.isNegative ? Duration.zero : age;
  }

  bool canManage(CalendarConnection connection) =>
      canConnect && connection.mayBeManagedBy(uid: viewerUid, isAdmin: isAdmin);

  /// Whether [provider] can be connected here. Unknown — still loading, or the
  /// question failed — reads as yes: the attempt itself will say why not.
  bool isAvailable(CalendarProvider provider) => switch (_availability) {
    AsyncData(:final value) => value.isAvailable(provider),
    _ => true,
  };

  /// Opens the provider's consent page. The rest happens between the browser
  /// and a Function; the new connection arrives through the listener.
  Future<void> connect(CalendarProvider provider) async {
    if (_isConnecting) return;
    _isConnecting = true;
    notifyListeners();
    await runAction(() async {
      final page = await _directory.startConnection(householdId, provider);
      if (!await _opener.open(page)) {
        throw const CalendarSyncFailure(
          CalendarSyncProblem.couldNotOpenBrowser,
        );
      }
      _awaitingBrowser = true;
      _connectionsWhenBrowserOpened = _connectionCount;
    });
    _isConnecting = false;
    notifyListeners();
  }

  /// Connects a calendar link. True when it was connected, so the sheet that
  /// asked can close; false leaves the refusal on [actionFailure].
  Future<bool> connectLink(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || _isConnecting) return false;
    _isConnecting = true;
    notifyListeners();
    var connected = false;
    await runAction(() async {
      await _directory.connectLink(householdId, trimmed);
      connected = true;
    });
    _isConnecting = false;
    notifyListeners();
    return connected;
  }

  Future<void> syncNow(CalendarConnection connection) => _whileBusy(
    connection,
    () => _directory.syncNow(householdId, connection.id),
  );

  Future<void> disconnect(CalendarConnection connection) => _whileBusy(
    connection,
    () => _directory.disconnect(householdId, connection.id),
  );

  Future<void> shareFeed() =>
      _feedAction(() => _directory.shareFeed(householdId));

  Future<void> resetFeed() =>
      _feedAction(() => _directory.resetFeed(householdId));

  /// Hands the feed to the phone's calendar app as a subscription.
  Future<void> subscribeToFeed() async {
    final feed = _feed;
    if (feed == null) return;
    await runAction(() async {
      if (!await _opener.open(feed.subscription)) {
        throw const CalendarSyncFailure(
          CalendarSyncProblem.couldNotOpenBrowser,
        );
      }
    });
  }

  Future<void> retry() async {
    await _cancel();
    _connections = const AsyncLoading();
    notifyListeners();
    _listen();
    await _loadAvailability();
  }

  int get _connectionCount => switch (_connections) {
    AsyncData(:final value) => value.length,
    _ => 0,
  };

  void _listen() {
    _connectionSubscription = _repository
        .watchConnections(householdId)
        .listen(_onConnections, onError: _onConnectionsError);
    _feedSubscription = _repository.watchFeedLink(householdId).listen((feed) {
      _feed = feed;
      notifyListeners();
    }, onError: (Object error) => recordFailure(_asFailure(error)));
  }

  void _onConnections(List<CalendarConnection> connections) {
    _connections = AsyncData([...connections]..sort(_byProviderThenLabel));
    final before = _connectionsWhenBrowserOpened;
    if (_awaitingBrowser && before != null && connections.length > before) {
      _awaitingBrowser = false;
      _connectionsWhenBrowserOpened = null;
    }
    notifyListeners();
  }

  void _onConnectionsError(Object error) {
    _connections = AsyncFailure(_asFailure(error));
    notifyListeners();
  }

  Future<void> _loadAvailability() async {
    try {
      _availability = AsyncData(
        await _directory.availableProviders(householdId),
      );
    } on AppFailure catch (failure) {
      _availability = AsyncFailure(failure);
    }
    notifyListeners();
  }

  Future<void> _whileBusy(
    CalendarConnection connection,
    Future<void> Function() action,
  ) async {
    if (!_busy.add(connection.id)) return;
    notifyListeners();
    await runAction(action);
    _busy.remove(connection.id);
    notifyListeners();
  }

  Future<void> _feedAction(Future<void> Function() action) async {
    if (_isSharingFeed) return;
    _isSharingFeed = true;
    notifyListeners();
    // The link arrives through the listener like everything else, so there is
    // one answer to "what is the link", not two (`FE-07`).
    await runAction(action);
    _isSharingFeed = false;
    notifyListeners();
  }

  static AppFailure _asFailure(Object error) =>
      error is AppFailure ? error : UnknownFailure(error);

  static int _byProviderThenLabel(CalendarConnection a, CalendarConnection b) {
    final byProvider = a.provider.index.compareTo(b.provider.index);
    if (byProvider != 0) return byProvider;
    final byLabel = a.accountLabel.compareTo(b.accountLabel);
    return byLabel != 0 ? byLabel : a.id.compareTo(b.id);
  }

  Future<void> _cancel() async {
    await _connectionSubscription?.cancel();
    await _feedSubscription?.cancel();
    _connectionSubscription = null;
    _feedSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
