import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../data/assistant_repository.dart';
import '../model/assistant_activity.dart';
import '../model/assistant_connection.dart';

/// *Connected assistants*' controller (assistants ADR-0003, ADR-0005): the
/// connections this member may see — every one in the household for family,
/// only their own for anybody else, as the rules allow — what each has done
/// lately, the household's switch, and the two actions, whose refusals are
/// held for the screen to put into words.
///
/// It holds nothing the listeners do not (`FE-07`): a disconnected
/// assistant leaves this screen because its document went, and the switch
/// moves because the settings document did.
final class ConnectedAssistantsController extends ChangeNotifier
    with ActionFailureHolder {
  ConnectedAssistantsController({
    required AssistantRepository assistantRepository,
    required HouseholdClock householdClock,
    required this.householdId,
    required this.viewerUid,
    required this.viewerMemberId,
    required this.isFamily,
  }) : _repository = assistantRepository,
       _clock = householdClock {
    _listen();
  }

  final AssistantRepository _repository;
  final HouseholdClock _clock;
  final String householdId;
  final String viewerUid;
  final String viewerMemberId;

  /// Family see every connection and own the household's switch; anybody
  /// else sees only what they connected (assistants ADR-0003).
  final bool isFamily;

  /// How many of a connection's latest changes the screen lists.
  static const recentLimit = 3;

  StreamSubscription<List<AssistantConnection>>? _connectionSubscription;
  StreamSubscription<List<AssistantActivity>>? _activitySubscription;
  StreamSubscription<bool>? _allowedSubscription;

  AsyncState<List<AssistantConnection>> _connections = const AsyncLoading();
  Map<String, List<AssistantActivity>> _activityByGrant = const {};
  bool? _allowed;
  bool _isSwitching = false;
  final _busy = <String>{};

  AsyncState<List<AssistantConnection>> get connections => _connections;

  /// Whether assistants may work here; null until the settings have been
  /// read.
  bool? get allowed => _allowed;

  bool get isSwitching => _isSwitching;

  bool isBusy(AssistantConnection connection) => _busy.contains(connection.id);

  bool isOwn(AssistantConnection connection) => connection.uid == viewerUid;

  /// The rules let the member who connected it, or family, delete a grant.
  bool canDisconnect(AssistantConnection connection) =>
      isFamily || isOwn(connection);

  /// The connection's latest changes, newest first.
  List<AssistantActivity> recentActivityOf(AssistantConnection connection) =>
      _activityByGrant[connection.id] ?? const [];

  CalendarDate get today => _clock.today;

  CalendarDate dayOf(DateTime instant) => _clock.dateOf(instant);

  /// How long ago [instant] was, never negative when a phone's clock runs
  /// behind the server's.
  Duration since(DateTime instant) {
    final age = _clock.now.difference(instant);
    return age.isNegative ? Duration.zero : age;
  }

  Future<void> disconnect(AssistantConnection connection) async {
    if (!_busy.add(connection.id)) return;
    notifyListeners();
    await runAction(
      () => _repository.disconnect(
        householdId: householdId,
        connectionId: connection.id,
      ),
    );
    _busy.remove(connection.id);
    notifyListeners();
  }

  Future<void> setAllowed(bool allowed) async {
    if (!isFamily || _isSwitching) return;
    _isSwitching = true;
    notifyListeners();
    await runAction(
      () => _repository.setAllowed(
        householdId: householdId,
        allowed: allowed,
        memberId: viewerMemberId,
      ),
    );
    _isSwitching = false;
    notifyListeners();
  }

  Future<void> retry() async {
    await _cancel();
    _connections = const AsyncLoading();
    notifyListeners();
    _listen();
  }

  void _listen() {
    _connectionSubscription = _repository
        .watchConnections(householdId, ownerUid: isFamily ? null : viewerUid)
        .listen(_onConnections, onError: _onConnectionsError);
    _activitySubscription = _repository
        .watchActivity(householdId, memberId: isFamily ? null : viewerMemberId)
        .listen(_onActivity, onError: _onSideReadError);
    _allowedSubscription = _repository.watchAllowed(householdId).listen((
      allowed,
    ) {
      _allowed = allowed;
      notifyListeners();
    }, onError: _onSideReadError);
  }

  void _onConnections(List<AssistantConnection> connections) {
    _connections = AsyncData([...connections]..sort(_ownFirstThenNewest));
    notifyListeners();
  }

  void _onConnectionsError(Object error) {
    _connections = AsyncFailure(_asFailure(error));
    notifyListeners();
  }

  void _onActivity(List<AssistantActivity> activity) {
    final byGrant = <String, List<AssistantActivity>>{};
    for (final entry in [...activity]..sort(_newestFirst)) {
      final recent = byGrant.putIfAbsent(entry.grantId, () => []);
      if (recent.length < recentLimit) recent.add(entry);
    }
    _activityByGrant = byGrant;
    notifyListeners();
  }

  /// The activity and the switch are beside the list, not the list, so a
  /// failed read is a banner rather than the screen's error state.
  void _onSideReadError(Object error) => recordFailure(_asFailure(error));

  int _ownFirstThenNewest(AssistantConnection a, AssistantConnection b) {
    final byOwner = (isOwn(a) ? 0 : 1).compareTo(isOwn(b) ? 0 : 1);
    if (byOwner != 0) return byOwner;
    final byAge = _compareNewestFirst(a.createdAt, b.createdAt);
    return byAge != 0 ? byAge : a.id.compareTo(b.id);
  }

  static int _newestFirst(AssistantActivity a, AssistantActivity b) =>
      _compareNewestFirst(a.at, b.at);

  /// A time the server has not stamped yet is the newest of all.
  static int _compareNewestFirst(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return (a == null ? 0 : 1) - (b == null ? 0 : 1);
    }
    return b.compareTo(a);
  }

  static AppFailure _asFailure(Object error) =>
      error is AppFailure ? error : UnknownFailure(error);

  Future<void> _cancel() async {
    await _connectionSubscription?.cancel();
    await _activitySubscription?.cancel();
    await _allowedSubscription?.cancel();
    _connectionSubscription = null;
    _activitySubscription = null;
    _allowedSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
