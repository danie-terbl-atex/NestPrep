import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/diagnostics/model/emulator_ping.dart';

void main() {
  test('parses a document with its id and a server timestamp', () {
    final ping = EmulatorPing.fromJson({
      'id': 'abc',
      'sentFrom': 'android',
      'sentAt': Timestamp.fromDate(DateTime.utc(2026, 9, 17)),
    });
    expect(ping.id, 'abc');
    expect(ping.sentFrom, 'android');
    expect(ping.sentAt, DateTime.utc(2026, 9, 17));
  });

  test('never writes the document id as a field', () {
    const ping = EmulatorPing(id: 'abc', sentFrom: 'android');
    expect(ping.toJson().containsKey('id'), isFalse);
    expect(ping.toJson()['sentAt'], isA<FieldValue>());
  });
}
