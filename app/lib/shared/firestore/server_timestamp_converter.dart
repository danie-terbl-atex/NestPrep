import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// A `DateTime?` field whose value the server assigns. Writing `null` sends a
/// server timestamp, so rules can insist on `request.time` (foundation
/// ADR-0002); reading `null` means the write is still pending locally.
class ServerTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const ServerTimestampConverter();

  @override
  DateTime? fromJson(Object? json) => switch (json) {
    Timestamp() => json.toDate().toUtc(),
    null => null,
    _ => throw FormatException('expected a Timestamp', json),
  };

  @override
  Object toJson(DateTime? value) => value == null
      ? FieldValue.serverTimestamp()
      : Timestamp.fromDate(value.toUtc());
}
