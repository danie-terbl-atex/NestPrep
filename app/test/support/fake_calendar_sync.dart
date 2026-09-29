import 'dart:async';

import 'package:nestprep/features/calendar_sync/data/calendar_sync_directory.dart';
import 'package:nestprep/features/calendar_sync/data/calendar_sync_repository.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_connection.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_feed_link.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/model/provider_availability.dart';
import 'package:nestprep/features/calendar_sync/model/synced_event.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/links/external_link_opener.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Calendar sync's three reads, driven by hand. Until a test emits, the synced
/// events stream is empty — which is what a household with nothing connected
/// sees, and what every calendar test that predates sync expects.
final class FakeCalendarSyncRepository implements CalendarSyncRepository {
  final _connections = StreamController<List<CalendarConnection>>.broadcast();
  final _feed = StreamController<CalendarFeedLink?>.broadcast();
  StreamController<List<SyncedEvent>> _synced =
      StreamController<List<SyncedEvent>>.broadcast();

  final syncedWindows = <({CalendarDate from, CalendarDate to})>[];

  void emitConnections(List<CalendarConnection> connections) =>
      _connections.add(connections);
  void failConnectionsWith(Object error) => _connections.addError(error);
  void emitFeed(CalendarFeedLink? feed) => _feed.add(feed);
  void emitSynced(List<SyncedEvent> events) => _synced.add(events);
  void failSyncedWith(Object error) => _synced.addError(error);

  Future<void> close() async {
    await _connections.close();
    await _feed.close();
    await _synced.close();
  }

  @override
  Stream<List<CalendarConnection>> watchConnections(String householdId) =>
      _connections.stream;

  @override
  Stream<CalendarFeedLink?> watchFeedLink(String householdId) => _feed.stream;

  @override
  Stream<List<SyncedEvent>> watchSyncedEvents(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
  }) {
    syncedWindows.add((from: from, to: to));
    if (_synced.hasListener) {
      _synced = StreamController<List<SyncedEvent>>.broadcast();
    }
    return _synced.stream;
  }
}

/// The callables, answering from fields a test sets, and remembering calls.
final class FakeCalendarSyncDirectory implements CalendarSyncDirectory {
  ProviderAvailability availability = const ProviderAvailability(
    google: true,
    microsoft: false,
  );
  AppFailure? failWith;
  AppFailure? failAvailabilityWith;
  Uri consentPage = Uri.parse('https://accounts.google.com/o/oauth2/v2/auth');
  String feedUrl = 'https://feed.test/calendarFeed?token=abc';

  final started = <CalendarProvider>[];
  final linked = <String>[];
  final synced = <String>[];
  final disconnected = <String>[];
  int feedsShared = 0;
  int feedsReset = 0;

  @override
  Future<ProviderAvailability> availableProviders(String householdId) async {
    final failure = failAvailabilityWith;
    if (failure != null) throw failure;
    return availability;
  }

  @override
  Future<Uri> startConnection(
    String householdId,
    CalendarProvider provider,
  ) async {
    _refuseIfAsked();
    started.add(provider);
    return consentPage;
  }

  @override
  Future<void> connectLink(String householdId, String url) async {
    _refuseIfAsked();
    linked.add(url);
  }

  @override
  Future<void> syncNow(String householdId, String connectionId) async {
    _refuseIfAsked();
    synced.add(connectionId);
  }

  @override
  Future<void> disconnect(String householdId, String connectionId) async {
    _refuseIfAsked();
    disconnected.add(connectionId);
  }

  @override
  Future<CalendarFeedLink> shareFeed(String householdId) async {
    _refuseIfAsked();
    feedsShared++;
    return CalendarFeedLink(feedUrl);
  }

  @override
  Future<CalendarFeedLink> resetFeed(String householdId) async {
    _refuseIfAsked();
    feedsReset++;
    return CalendarFeedLink(feedUrl);
  }

  void _refuseIfAsked() {
    final failure = failWith;
    if (failure != null) throw failure;
  }
}

/// A phone where opening a link works, or — when told — does not.
final class FakeLinkOpener implements ExternalLinkOpener {
  bool opens = true;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri link) async {
    opened.add(link);
    return opens;
  }
}
