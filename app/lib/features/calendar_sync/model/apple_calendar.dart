/// Whether this phone lets NestPrep read its calendars.
enum AppleCalendarAccess { notDetermined, granted, denied, restricted }

/// One calendar on this iPhone: iCloud's, or an account added in Settings.
final class AppleCalendar {
  const AppleCalendar({
    required this.id,
    required this.title,
    required this.account,
    required this.suggested,
  });

  final String id;
  final String title;

  /// "iCloud", "Gmail", "Exchange" — where the calendar lives.
  final String account;

  /// On unless it is the birthdays calendar or a subscribed one.
  final bool suggested;
}

/// One occurrence read from the phone, in the shape `pushAppleCalendar` takes.
sealed class AppleOccurrence {
  const AppleOccurrence({required this.id, required this.title});

  final String id;
  final String title;

  DateTime get sortKey;

  Map<String, Object> toPayload();
}

final class TimedAppleOccurrence extends AppleOccurrence {
  const TimedAppleOccurrence({
    required super.id,
    required super.title,
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  @override
  DateTime get sortKey => start;

  @override
  Map<String, Object> toPayload() => {
    'id': id,
    'title': title,
    'allDay': false,
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
  };
}

final class AllDayAppleOccurrence extends AppleOccurrence {
  const AllDayAppleOccurrence({
    required super.id,
    required super.title,
    required this.startDate,
    required this.endDateExclusive,
  });

  /// `YYYY-MM-DD`.
  final String startDate;
  final String endDateExclusive;

  @override
  DateTime get sortKey => DateTime.parse(startDate);

  @override
  Map<String, Object> toPayload() => {
    'id': id,
    'title': title,
    'allDay': true,
    'startDate': startDate,
    'endDateExclusive': endDateExclusive,
  };
}

/// What this phone remembers about the Apple Calendar it linked to one
/// household: which calendars, and what it last sent.
final class AppleCalendarLink {
  const AppleCalendarLink({
    required this.connectionId,
    required this.calendarIds,
    this.digest = '',
    this.pushedAt,
  });

  final String connectionId;
  final List<String> calendarIds;

  /// A hash of the last payload the server took, so an unchanged calendar is
  /// not sent again.
  final String digest;
  final DateTime? pushedAt;

  AppleCalendarLink copyWith({
    List<String>? calendarIds,
    String? digest,
    DateTime? pushedAt,
  }) => AppleCalendarLink(
    connectionId: connectionId,
    calendarIds: calendarIds ?? this.calendarIds,
    digest: digest ?? this.digest,
    pushedAt: pushedAt ?? this.pushedAt,
  );

  Map<String, Object?> toJson() => {
    'connectionId': connectionId,
    'calendarIds': calendarIds,
    'digest': digest,
    'pushedAt': pushedAt?.toUtc().toIso8601String(),
  };

  static AppleCalendarLink? fromJson(Object? json) {
    if (json is! Map) return null;
    final connectionId = json['connectionId'];
    final calendarIds = json['calendarIds'];
    if (connectionId is! String || calendarIds is! List) return null;
    final digest = json['digest'];
    final pushedAt = json['pushedAt'];
    return AppleCalendarLink(
      connectionId: connectionId,
      calendarIds: calendarIds.whereType<String>().toList(),
      digest: digest is String ? digest : '',
      pushedAt: pushedAt is String ? DateTime.tryParse(pushedAt) : null,
    );
  }
}
