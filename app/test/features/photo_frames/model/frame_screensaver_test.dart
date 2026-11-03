import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/model/frame_screensaver.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';

void main() {
  PhotoFrame frameWith(Object? screensaver, {bool present = true}) =>
      PhotoFrame.fromJson({
        'id': 'f1',
        'name': 'Kitchen frame',
        if (present) 'screensaver': screensaver,
      });

  test('a frame linked before screensavers has it off', () {
    expect(frameWith(null, present: false).screensaver, FrameScreensaver.off);
    expect(frameWith(null).screensaver, FrameScreensaver.off);
    expect(FrameScreensaver.off.isOn, isFalse);
  });

  test('reads what the app writes', () {
    const saver = FrameScreensaver(idleMinutes: 5, secondsPerPhoto: 30);
    expect(frameWith(saver.toJson()).screensaver, saver);
    expect(saver.isOn, isTrue);
  });

  test('writes the exact shape the rules ask for', () {
    expect(const FrameScreensaver(idleMinutes: 10).toJson(), {
      'idleMinutes': 10,
      'secondsPerPhoto': 20,
    });
    expect(FrameScreensaver.off.toJson(), {
      'idleMinutes': 0,
      'secondsPerPhoto': 20,
    });
  });

  group('junk is off, never a crash', () {
    for (final junk in <Object?>[
      'five',
      42,
      <Object?>[5, 30],
      {'idleMinutes': 7, 'secondsPerPhoto': 30},
      {'idleMinutes': '5'},
      {'idleMinutes': 2.5},
      {'idleMinutes': -1},
      {'secondsPerPhoto': 30},
      {'idleMinutes': 0, 'secondsPerPhoto': 60},
    ]) {
      test('$junk', () {
        expect(frameWith(junk).screensaver, FrameScreensaver.off);
      });
    }
  });

  test('a pace it does not know falls back to the usual one', () {
    expect(
      frameWith({'idleMinutes': 15, 'secondsPerPhoto': 45}).screensaver,
      const FrameScreensaver(idleMinutes: 15),
    );
    expect(
      frameWith({'idleMinutes': 1.0, 'secondsPerPhoto': 10.0}).screensaver,
      const FrameScreensaver(idleMinutes: 1, secondsPerPhoto: 10),
    );
  });

  test('every choice is one the frame understands', () {
    expect(FrameScreensaver.idleMinuteChoices, [0, 1, 2, 5, 10, 15, 30, 60]);
    expect(FrameScreensaver.secondsPerPhotoChoices, [10, 20, 30, 60]);
    expect(
      FrameScreensaver.secondsPerPhotoChoices,
      contains(FrameScreensaver.defaultSecondsPerPhoto),
    );
  });
}
