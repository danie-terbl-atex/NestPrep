import 'package:nestprep/features/calendar_sync/data/apple_calendar_link_store.dart';
import 'package:nestprep/features/calendar_sync/data/apple_calendar_reader.dart';
import 'package:nestprep/features/calendar_sync/model/apple_calendar.dart';

/// This iPhone's calendars, as a test sets them.
final class FakeAppleCalendarReader implements AppleCalendarReader {
  FakeAppleCalendarReader({this.isAvailable = true});

  @override
  final bool isAvailable;

  AppleCalendarAccess current = AppleCalendarAccess.granted;
  AppleCalendarAccess answerToRequest = AppleCalendarAccess.granted;
  List<AppleCalendar> calendarList = const [];
  List<AppleOccurrence> found = const [];

  int requests = 0;
  int settingsOpened = 0;
  final reads = <({List<String> calendarIds, DateTime from, DateTime to})>[];

  @override
  Future<AppleCalendarAccess> access() async => current;

  @override
  Future<AppleCalendarAccess> requestAccess() async {
    requests++;
    current = answerToRequest;
    return current;
  }

  @override
  Future<List<AppleCalendar>> calendars() async => calendarList;

  @override
  Future<List<AppleOccurrence>> occurrences({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async {
    reads.add((calendarIds: calendarIds, from: from, to: to));
    return found;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

final class MemoryAppleCalendarLinkStore implements AppleCalendarLinkStore {
  final links = <String, AppleCalendarLink>{};

  @override
  Future<AppleCalendarLink?> read(String uid, String householdId) async =>
      links['$uid/$householdId'];

  @override
  Future<void> write(
    String uid,
    String householdId,
    AppleCalendarLink link,
  ) async => links['$uid/$householdId'] = link;

  @override
  Future<void> clear(String uid, String householdId) async =>
      links.remove('$uid/$householdId');
}
