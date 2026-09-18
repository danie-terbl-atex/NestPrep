import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// A `DateTime` a caller chose and that must be there: a deadline, a window's
/// end. It is stored as a `Timestamp` like every other instant in this app and
/// read back in UTC (`ENG-21`).
///
/// Neither of the two converters beside it fits. `ServerTimestampConverter` is
/// for a field the *server* assigns, and writes a sentinel for null;
/// `NullableTimestampConverter` is for one that is genuinely optional, where
/// null means *not yet*. A share's `sharingUntil` is neither — the member
/// picked it, and a rule refuses the write if it is missing.
class InstantConverter implements JsonConverter<DateTime, Object?> {
  const InstantConverter();

  @override
  DateTime fromJson(Object? json) => switch (json) {
    Timestamp() => json.toDate().toUtc(),
    _ => throw FormatException('expected a Timestamp', json),
  };

  @override
  Object toJson(DateTime value) => Timestamp.fromDate(value.toUtc());
}
