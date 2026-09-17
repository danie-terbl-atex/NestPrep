import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/firestore/server_timestamp_converter.dart';

void main() {
  const converter = ServerTimestampConverter();

  test('a null value is written as a server timestamp', () {
    expect(converter.toJson(null), isA<FieldValue>());
  });

  test('a value round-trips through a Firestore Timestamp in UTC', () {
    final instant = DateTime.utc(2026, 9, 17, 18, 30);
    final written = converter.toJson(instant);
    expect(written, isA<Timestamp>());
    expect(converter.fromJson(written), instant);
  });

  test('a pending server timestamp reads as null', () {
    expect(converter.fromJson(null), isNull);
  });

  test('anything that is not a Timestamp is rejected, not cast', () {
    expect(() => converter.fromJson('2026-09-17'), throwsFormatException);
  });
}
