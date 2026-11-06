import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/apple_calendar_link_store.dart';
import '../data/apple_calendar_reader.dart';
import '../data/calendar_sync_directory.dart';
import '../model/apple_calendar.dart';

/// Apple Calendar, read on this iPhone and pushed to the household. Apple has
/// no server API, so the phone is the only thing that can read it; the server
/// files what it sends exactly as it files a Google sync, so the week, the
/// frame and the feed cannot tell the two apart.
///
/// App-wide, because what it remembers outlives every screen. A push only
/// goes out when the calendars changed or the last one is half a day old.
final class AppleCalendarSync {
  AppleCalendarSync({
    required this._reader,
    required this._store,
    required this._directory,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const daysBack = 8;
  static const daysAhead = 122;
  static const maxOccurrences = 1000;
  static const refreshAfter = Duration(hours: 12);

  final AppleCalendarReader _reader;
  final AppleCalendarLinkStore _store;
  final CalendarSyncDirectory _directory;
  final DateTime Function() _now;
  final _inFlight = <String, Future<void>>{};

  bool get isAvailable => _reader.isAvailable;

  Future<AppleCalendarAccess> access() => _reader.access();

  Future<List<AppleCalendar>> calendars() => _reader.calendars();

  Future<void> openSettings() => _reader.openSettings();

  Future<AppleCalendarLink?> linkFor(String uid, String householdId) =>
      _store.read(uid, householdId);

  /// Asks for access when it has never been asked, and refuses in words when
  /// the answer is no.
  Future<void> ensureAccess() async {
    var access = await _reader.access();
    if (access == AppleCalendarAccess.notDetermined) {
      access = await _reader.requestAccess();
    }
    switch (access) {
      case AppleCalendarAccess.granted:
        return;
      case AppleCalendarAccess.restricted:
        throw const CalendarSyncFailure(
          CalendarSyncProblem.appleCalendarRestricted,
        );
      case AppleCalendarAccess.denied || AppleCalendarAccess.notDetermined:
        throw const CalendarSyncFailure(
          CalendarSyncProblem.appleCalendarDenied,
        );
    }
  }

  /// Files [calendarIds] for this member, or changes which calendars an
  /// existing link reads, and sends what they hold.
  Future<void> link(
    String uid,
    String householdId,
    List<String> calendarIds,
  ) async {
    if (calendarIds.isEmpty) {
      throw const CalendarSyncFailure(
        CalendarSyncProblem.noAppleCalendarChosen,
      );
    }
    await ensureAccess();
    final occurrences = await _read(calendarIds);
    final connectionId = await _directory.pushAppleCalendar(
      householdId,
      link: true,
      occurrences: occurrences,
    );
    await _store.write(
      uid,
      householdId,
      AppleCalendarLink(
        connectionId: connectionId,
        calendarIds: calendarIds,
        digest: digestOf(occurrences),
        pushedAt: _now(),
      ),
    );
  }

  /// Sends this phone's calendars when they changed, or [force]d. Nothing
  /// when this phone linked nothing here or has lost access. A connection the
  /// server no longer has — disconnected from another phone — is forgotten,
  /// so it is not filed again.
  Future<void> pushIfDue(String uid, String householdId, {bool force = false}) {
    final key = '$uid/$householdId';
    return _inFlight[key] ??= _push(uid, householdId, force: force)
        .whenComplete(() {
          _inFlight.remove(key);
        });
  }

  Future<void> forget(String uid, String householdId) =>
      _store.clear(uid, householdId);

  Future<void> _push(
    String uid,
    String householdId, {
    required bool force,
  }) async {
    final link = await _store.read(uid, householdId);
    if (link == null) return;
    if (await _reader.access() != AppleCalendarAccess.granted) {
      if (force) await ensureAccess();
      return;
    }
    final occurrences = await _read(link.calendarIds);
    final digest = digestOf(occurrences);
    final pushedAt = link.pushedAt;
    final isFresh =
        pushedAt != null && _now().difference(pushedAt) < refreshAfter;
    if (!force && digest == link.digest && isFresh) return;
    try {
      await _directory.pushAppleCalendar(
        householdId,
        link: false,
        occurrences: occurrences,
      );
    } on CalendarSyncFailure catch (failure) {
      if (failure.problem == CalendarSyncProblem.connectionNotFound ||
          failure.problem == CalendarSyncProblem.notYourConnection) {
        await _store.clear(uid, householdId);
      }
      rethrow;
    }
    await _store.write(
      uid,
      householdId,
      link.copyWith(digest: digest, pushedAt: _now()),
    );
  }

  Future<List<AppleOccurrence>> _read(List<String> calendarIds) async {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final found = await _reader.occurrences(
      calendarIds: calendarIds,
      from: today.subtract(const Duration(days: daysBack)),
      to: today.add(const Duration(days: daysAhead)),
    );
    final sorted = [...found]
      ..sort((a, b) {
        final byStart = a.sortKey.compareTo(b.sortKey);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });
    return sorted.take(maxOccurrences).toList();
  }

  static String digestOf(List<AppleOccurrence> occurrences) => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            for (final occurrence in occurrences) occurrence.toPayload(),
          ]),
        ),
      )
      .toString();
}
