import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_tags.dart';
import 'package:nestprep/features/documents/model/expiry_schedule.dart';

/// Two contracts written down on both sides of the client/server line, read
/// from both sides so they cannot drift (the vault's lesson on contracts
/// between two languages):
///
/// - the reminder offsets, which the daily sweep raises reminders at and the
///   badges turn colour at (documents ADR-0005);
/// - the tag limits, which `firestore.rules` enforces and the tag field stops
///   at before the write is refused (`FE-04`).
void main() {
  final schedule = File('../functions/src/documents/expiry_schedule.ts');
  final rules = File('../firestore.rules');

  test('both sources are where this test thinks they are', () {
    expect(schedule.existsSync(), isTrue, reason: 'point the test at it');
    expect(rules.existsSync(), isTrue, reason: 'point the test at it');
  });

  test('the app and the sweep remind on the same days', () {
    final match = RegExp(
      r'EXPIRY_REMINDER_DAYS_BEFORE = \[([\d,\s]+)\]',
    ).firstMatch(schedule.readAsStringSync());
    expect(match, isNotNull, reason: 'the constant moved or changed shape');
    final serverDays = match!
        .group(1)!
        .split(',')
        .map((day) => int.parse(day.trim()))
        .toList();
    expect(ExpirySchedule.reminderDaysBefore, serverDays);
  });

  test('the tag field stops where the rules refuse', () {
    final source = rules.readAsStringSync();
    expect(source, contains('tags.size() <= ${DocumentTags.maxTags}'));
    expect(source, contains('tags[index].size() <= ${DocumentTags.maxLength}'));
    // One `isTagAt` per place the rules allow, or a ninth tag slips through.
    expect(
      RegExp(r'isTagAt\(tags, \d\)').allMatches(source).length,
      DocumentTags.maxTags,
    );
  });
}
