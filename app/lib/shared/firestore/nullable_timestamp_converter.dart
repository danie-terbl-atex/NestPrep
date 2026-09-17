import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// A `DateTime?` that is genuinely optional: null means *not yet*, not "the
/// server decides". A grocery item's `boughtAt` is null until somebody ticks
/// it, and the tick is what stamps the server's time.
///
/// This is the counterpart to `ServerTimestampConverter`, which is for a field
/// the server assigns once on write. Using that one here would write a
/// timestamp on every create — an item added would arrive already bought, and
/// the rules would refuse it.
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) => switch (json) {
    Timestamp() => json.toDate().toUtc(),
    null => null,
    _ => throw FormatException('expected a Timestamp or null', json),
  };

  @override
  Object? toJson(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value.toUtc());
}
