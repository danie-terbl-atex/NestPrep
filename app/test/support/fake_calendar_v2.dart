import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/mental_load/data/card_image_sharer.dart';
import 'package:nestprep/features/school_letter/data/letter_picker.dart';
import 'package:nestprep/features/school_letter/data/school_letter_reader.dart';
import 'package:nestprep/features/school_letter/model/letter_file.dart';
import 'package:nestprep/features/school_letter/model/letter_proposal.dart';
import 'package:nestprep/features/school_letter/model/letter_reading.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// A letter the fake picker hands back.
final aLetter = LetterFile(
  bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
  kind: LetterKind.jpeg,
);

/// The reader, answering what the test says — or holding the answer until
/// [complete] so a test can see the reading step.
final class FakeSchoolLetterReader implements SchoolLetterReader {
  LetterReading reading = const LetterReading(proposals: [], callsLeft: 9);
  AppFailure? failWith;
  Completer<void>? gate;
  final requests = <({String householdId, LetterFile letter})>[];

  void complete() => gate?.complete();

  @override
  Future<LetterReading> read({
    required String householdId,
    required LetterFile letter,
  }) async {
    requests.add((householdId: householdId, letter: letter));
    final waiting = gate;
    if (waiting != null) await waiting.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return reading;
  }
}

final class FakeLetterPicker implements LetterPicker {
  LetterFile? next = aLetter;
  AppFailure? failWith;
  final asked = <LetterSource>[];

  @override
  Future<LetterFile?> pick(LetterSource source) async {
    asked.add(source);
    final failure = failWith;
    if (failure != null) throw failure;
    return next;
  }
}

final class FakeCardImageSharer implements CardImageSharer {
  AppFailure? failWith;
  final shared = <({int bytes, String fileName, String text})>[];

  @override
  Future<void> share({
    required Uint8List png,
    required String fileName,
    required String text,
  }) async {
    final failure = failWith;
    if (failure != null) throw failure;
    shared.add((bytes: png.length, fileName: fileName, text: text));
  }
}

/// Two proposals: a timed outing for the kid, an all-day civvies day.
List<LetterProposal> twoProposals() => [
  LetterProposal(
    title: 'Grade 3 zoo outing',
    date: CalendarDate(2026, 10, 21),
    startMinute: 8 * 60 + 30,
    endMinute: 13 * 60,
    memberIds: const ['m-kid'],
    note: 'Bring a hat',
  ),
  LetterProposal(title: 'Civvies day', date: CalendarDate(2026, 10, 16)),
];
