import 'package:flutter/services.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/apple_calendar.dart';
import 'apple_calendar_reader.dart';

/// EventKit over `io.nullstate.nestprep/apple_calendar`
/// (`ios/Runner/AppleCalendarChannel.swift`). Every answer is parsed rather
/// than cast; anything malformed is dropped, not thrown.
final class MethodChannelAppleCalendarReader implements AppleCalendarReader {
  const MethodChannelAppleCalendarReader({
    this.isAvailable = true,
    this._channel = const MethodChannel(channelName),
  });

  static const channelName = 'io.nullstate.nestprep/apple_calendar';

  final MethodChannel _channel;

  @override
  final bool isAvailable;

  @override
  Future<AppleCalendarAccess> access() async => isAvailable
      ? accessFrom(await _guard(() => _channel.invokeMethod<String>('access')))
      : AppleCalendarAccess.restricted;

  @override
  Future<AppleCalendarAccess> requestAccess() async => isAvailable
      ? accessFrom(
          await _guard(() => _channel.invokeMethod<String>('requestAccess')),
        )
      : AppleCalendarAccess.restricted;

  @override
  Future<List<AppleCalendar>> calendars() async {
    if (!isAvailable) return const [];
    final raw =
        await _guard(() => _channel.invokeListMethod<Object?>('calendars')) ??
        [];
    return raw.map(calendarFrom).nonNulls.toList();
  }

  @override
  Future<List<AppleOccurrence>> occurrences({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async {
    if (!isAvailable || calendarIds.isEmpty) return const [];
    final raw =
        await _guard(
          () => _channel.invokeListMethod<Object?>('occurrences', {
            'calendarIds': calendarIds,
            'fromMs': from.millisecondsSinceEpoch,
            'toMs': to.millisecondsSinceEpoch,
          }),
        ) ??
        [];
    return raw.map(occurrenceFrom).nonNulls.toList();
  }

  @override
  Future<void> openSettings() async {
    if (isAvailable) {
      await _guard(() => _channel.invokeMethod<void>('openSettings'));
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error) {
      throw UnknownFailure(error);
    }
  }

  static AppleCalendarAccess accessFrom(String? name) =>
      AppleCalendarAccess.values
          .where((value) => value.name == name)
          .firstOrNull ??
      AppleCalendarAccess.denied;

  static AppleCalendar? calendarFrom(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    if (id is! String || id.isEmpty || title is! String) return null;
    final account = raw['account'];
    return AppleCalendar(
      id: id,
      title: title,
      account: account is String ? account : '',
      suggested: raw['suggested'] != false,
    );
  }

  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static AppleOccurrence? occurrenceFrom(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    if (id is! String || id.isEmpty || title is! String) return null;
    if (raw['allDay'] == true) {
      final startDate = raw['startDate'];
      final endDateExclusive = raw['endDateExclusive'];
      if (startDate is! String || !_date.hasMatch(startDate)) return null;
      if (endDateExclusive is! String || !_date.hasMatch(endDateExclusive)) {
        return null;
      }
      return AllDayAppleOccurrence(
        id: id,
        title: title,
        startDate: startDate,
        endDateExclusive: endDateExclusive,
      );
    }
    final start = raw['start'];
    final end = raw['end'];
    if (start is! int || end is! int) return null;
    return TimedAppleOccurrence(
      id: id,
      title: title,
      start: DateTime.fromMillisecondsSinceEpoch(start, isUtc: true),
      end: DateTime.fromMillisecondsSinceEpoch(end, isUtc: true),
    );
  }
}
