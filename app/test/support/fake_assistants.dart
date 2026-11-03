import 'dart:async';

import 'package:nestprep/features/assistants/data/assistant_repository.dart';
import 'package:nestprep/features/assistants/model/assistant_activity.dart';
import 'package:nestprep/features/assistants/model/assistant_connection.dart';
import 'package:nestprep/features/assistants/model/assistant_via.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import 'household_fixtures.dart';

/// *Connected assistants*' reads, driven by hand, and its two writes,
/// remembered. A disconnect that succeeds takes the connection off the list
/// and emits again, as the listener would once the grant is deleted.
final class FakeAssistantRepository implements AssistantRepository {
  final _connections = StreamController<List<AssistantConnection>>.broadcast();
  final _activity = StreamController<List<AssistantActivity>>.broadcast();
  final _allowed = StreamController<bool>.broadcast();

  var connections = <AssistantConnection>[];

  /// Set to make the next write fail, the way a rules denial or a phone with
  /// no signal does.
  AppFailure? failWritesWith;

  final connectionOwners = <String?>[];
  final activityMembers = <String?>[];
  final disconnected = <String>[];
  final allowedWrites = <({bool allowed, String memberId})>[];

  void emitConnections(List<AssistantConnection> value) {
    connections = value;
    _connections.add(value);
  }

  void failConnectionsWith(Object error) => _connections.addError(error);
  void emitActivity(List<AssistantActivity> value) => _activity.add(value);
  void failActivityWith(Object error) => _activity.addError(error);
  void emitAllowed(bool value) => _allowed.add(value);

  Future<void> close() async {
    await _connections.close();
    await _activity.close();
    await _allowed.close();
  }

  @override
  Stream<List<AssistantConnection>> watchConnections(
    String householdId, {
    String? ownerUid,
  }) {
    connectionOwners.add(ownerUid);
    return _connections.stream;
  }

  @override
  Stream<List<AssistantActivity>> watchActivity(
    String householdId, {
    String? memberId,
  }) {
    activityMembers.add(memberId);
    return _activity.stream;
  }

  @override
  Stream<bool> watchAllowed(String householdId) => _allowed.stream;

  @override
  Future<void> disconnect({
    required String householdId,
    required String connectionId,
  }) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    disconnected.add(connectionId);
    emitConnections([
      for (final connection in connections)
        if (connection.id != connectionId) connection,
    ]);
  }

  @override
  Future<void> setAllowed({
    required String householdId,
    required bool allowed,
    required String memberId,
  }) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    allowedWrites.add((allowed: allowed, memberId: memberId));
    _allowed.add(allowed);
  }
}

/// The instant the assistants tests read.
final assistantsNow = DateTime.utc(2026, 10, 29, 10);

/// A connection made through Claude, by Sam unless said otherwise.
AssistantConnection claudeConnection({
  String id = 'g-sam',
  String uid = Fixtures.samUid,
  String memberId = Fixtures.samMemberId,
  String clientName = 'Claude',
  AssistantVia via = AssistantVia.claude,
  List<String> scopes = const [
    'household:read',
    'calendar:read',
    'calendar:write',
    'lists:read',
    'lists:write',
  ],
  Duration? lastUsedAgo = const Duration(hours: 2),
}) => AssistantConnection(
  id: id,
  uid: uid,
  memberId: memberId,
  clientName: clientName,
  host: 'claude.ai',
  via: via,
  scopes: scopes,
  createdAt: DateTime.utc(2026, 10, 20, 8),
  lastUsedAt: lastUsedAgo == null ? null : assistantsNow.subtract(lastUsedAgo),
);

/// One change [grantId]'s assistant made, [ago] before [assistantsNow].
AssistantActivity assistantActivity(
  String id, {
  String grantId = 'g-sam',
  String memberId = Fixtures.samMemberId,
  String tool = 'create_event',
  Duration ago = const Duration(minutes: 30),
}) => AssistantActivity(
  id: id,
  grantId: grantId,
  memberId: memberId,
  via: AssistantVia.claude,
  tool: tool,
  at: assistantsNow.subtract(ago),
);
