import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/school_letter/data/device_letter_picker.dart';
import 'package:nestprep/features/school_letter/model/letter_file.dart';
import 'package:nestprep/features/school_letter/model/letter_proposal.dart';
import 'package:nestprep/features/school_letter/model/letter_reading.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/photos/jpeg_compressor.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// `readSchoolLetter`'s reply, parsed and never cast (`ENG-09`, calendar
/// ADR-0005): what the server sends becomes proposals, and anything that is
/// not one is left out rather than guessed at.
void main() {
  Map<String, Object?> wire([Map<String, Object?> changes = const {}]) => {
    'title': 'Swimming',
    'date': '2026-10-07',
    'startMinute': 14 * 60 + 30,
    'endMinute': 15 * 60 + 30,
    'recurrence': {
      'frequency': 'weekly',
      'interval': 1,
      'weekdays': [3],
      'until': '2026-12-02',
    },
    'memberIds': ['m-kid'],
    'note': 'Bring a towel',
    ...changes,
  };

  group('a proposal', () {
    test('comes across whole, on the wall clock, with its repeat', () {
      expect(
        LetterProposal.fromWire(wire()),
        LetterProposal(
          title: 'Swimming',
          date: CalendarDate(2026, 10, 7),
          startMinute: 870,
          endMinute: 930,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            weekdays: const [3],
            until: CalendarDate(2026, 12, 2),
          ),
          memberIds: const ['m-kid'],
          note: 'Bring a towel',
        ),
      );
    });

    test('with no start is all day, whatever end came with it', () {
      final proposal = LetterProposal.fromWire(
        wire({'startMinute': null, 'endMinute': 600}),
      );
      expect(proposal?.isAllDay, isTrue);
      expect(proposal?.endMinute, isNull);
    });

    test('is left out without a title or a real day', () {
      expect(LetterProposal.fromWire(wire({'title': '  '})), isNull);
      expect(LetterProposal.fromWire(wire({'date': '2026-02-31'})), isNull);
      expect(LetterProposal.fromWire(wire({'date': 7})), isNull);
      expect(LetterProposal.fromWire('not a map'), isNull);
    });

    test('drops a time that is not on a clock', () {
      expect(
        LetterProposal.fromWire(wire({'startMinute': 24 * 60}))?.startMinute,
        isNull,
      );
    });

    test('drops a repeat it cannot expand, and keeps the event once', () {
      final proposal = LetterProposal.fromWire(
        wire({
          'recurrence': {'frequency': 'yearly'},
        }),
      );
      expect(proposal?.recurrence, isNull);
      final bad = LetterProposal.fromWire(
        wire({
          'recurrence': {
            'frequency': 'weekly',
            'interval': 0,
            'weekdays': [9],
          },
        }),
      );
      expect(bad?.recurrence, isNull);
    });

    test('keeps only the member ids that are strings', () {
      final proposal = LetterProposal.fromWire(
        wire({
          'memberIds': ['m-kid', 7, '', null],
        }),
      );
      expect(proposal?.memberIds, ['m-kid']);
    });
  });

  group('a reading', () {
    test('keeps the proposals that parse and the calls left', () {
      final reading = LetterReading.fromWire({
        'proposals': [
          wire(),
          'junk',
          wire({'title': ''}),
        ],
        'callsLeft': 4,
      });
      expect(reading.proposals, hasLength(1));
      expect(reading.callsLeft, 4);
    });

    test('in the wrong shape altogether is an unreadable answer', () {
      for (final data in [
        null,
        'x',
        <String, Object?>{'proposals': []},
      ]) {
        expect(
          () => LetterReading.fromWire(data),
          throwsA(
            isA<AiFailure>().having(
              (failure) => failure.problem,
              'problem',
              AiProblem.aiUnreadable,
            ),
          ),
        );
      }
    });
  });

  group('a photo of a letter', () {
    test('leaves shrunk to the letter limit and stripped of its metadata', () {
      final photo = img.Image(width: 4000, height: 3000);
      photo.exif.imageIfd['Make'] = 'TestPhone';
      final bytes = Uint8List.fromList(img.encodeJpg(photo));
      final shrunk = JpegCompressor.compressNow(
        bytes,
        maxEdge: DeviceLetterPicker.maxEdge,
        jpegQuality: DeviceLetterPicker.jpegQuality,
      )!.bytes;
      final decoded = img.decodeJpg(shrunk)!;
      expect(decoded.width, DeviceLetterPicker.maxEdge);
      expect(decoded.exif.imageIfd['Make'], isNull);
      expect(shrunk.length, lessThan(LetterFile.maxBytes));
    });

    test('that is not a picture reads as nothing', () {
      expect(
        JpegCompressor.compressNow(
          Uint8List.fromList([1, 2, 3]),
          maxEdge: DeviceLetterPicker.maxEdge,
        ),
        isNull,
      );
    });

    test(
      'past the server’s limit is known to be too large before it is sent',
      () {
        final big = LetterFile(
          bytes: Uint8List(LetterFile.maxBytes + 1),
          kind: LetterKind.pdf,
        );
        expect(big.isTooLarge, isTrue);
        expect(LetterKind.pdf.mimeType, 'application/pdf');
      },
    );
  });
}
