import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/model/frame_code.dart';

void main() {
  group('a scanned code', () {
    test('the frame link is read for its code', () {
      expect(FrameCode.fromScan('nestprep://frame/ABC234'), 'ABC234');
    });

    test('in any case, and with stray space round it', () {
      expect(FrameCode.fromScan('  NestPrep://Frame/abc234 \n'), 'ABC234');
    });

    test('a bare code is a code', () {
      expect(FrameCode.fromScan('k7mq9z'), 'K7MQ9Z');
    });

    for (final raw in [
      'https://nestprep.app/frame/ABC234',
      'nestprep://kid/ABC234',
      'nestprep://frame/ABC234/extra',
      'nestprep://frame/ABC23',
      'nestprep://frame/ABC2345',
      'nestprep://frame/ABC23O',
      'ABC-234',
      'WIFI:S:home;T:WPA;P:secret;;',
      '',
    ]) {
      test('"$raw" is not one of ours', () {
        expect(FrameCode.fromScan(raw), isNull);
      });
    }
  });

  test('typing keeps only the letters a code can have', () {
    expect(FrameCode.normalise('ab-c 2o3i4l'), 'ABC234');
    expect(FrameCode.isComplete('ABC234'), isTrue);
    expect(FrameCode.isComplete('ABC23'), isFalse);
  });
}
