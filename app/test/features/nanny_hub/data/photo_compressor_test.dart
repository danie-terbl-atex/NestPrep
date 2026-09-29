import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/nanny_hub/data/photo_compressor.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// What leaves the phone when somebody adds a hub photo (nanny-hub ADR-0003):
/// small, upright, a JPEG, and carrying nothing about where it was taken.
void main() {
  Uint8List aPhoto({required int width, required int height, bool gps = true}) {
    final picture = img.Image(width: width, height: height);
    if (gps) {
      picture.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(26, 1);
      picture.exif.imageIfd['Make'] = img.IfdValueAscii('Phone');
    }
    return Uint8List.fromList(img.encodeJpg(picture));
  }

  test('a large photo leaves no longer than the long edge allows', () {
    final out = PhotoCompressor.compressNow(aPhoto(width: 4000, height: 3000))!;
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, PhotoCompressor.maxEdge);
    expect(decoded.height, 1200);
  });

  test('a tall photo is bounded by its height', () {
    final out = PhotoCompressor.compressNow(aPhoto(width: 1000, height: 3200))!;
    expect(img.decodeJpg(out)!.height, PhotoCompressor.maxEdge);
  });

  test('a small photo keeps its size', () {
    final out = PhotoCompressor.compressNow(aPhoto(width: 640, height: 480))!;
    expect(img.decodeJpg(out)!.width, 640);
  });

  test('carries no metadata out — not where it was taken, not the phone', () {
    final source = aPhoto(width: 800, height: 600);
    expect(img.decodeJpg(source)!.exif.isEmpty, isFalse);
    final out = PhotoCompressor.compressNow(source)!;
    expect(img.decodeJpg(out)!.exif.isEmpty, isTrue);
  });

  test('is a JPEG whatever it was given', () {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 10, height: 10)),
    );
    final out = PhotoCompressor.compressNow(png)!;
    expect(out.sublist(0, 2), [0xFF, 0xD8]);
  });

  test('is nothing at all when the bytes are not a picture', () {
    expect(PhotoCompressor.compressNow(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('says so, in the app’s words, off the UI thread', () async {
    await expectLater(
      PhotoCompressor.compress(Uint8List.fromList([1, 2, 3])),
      throwsA(
        isA<NannyHubFailure>().having(
          (failure) => failure.problem,
          'problem',
          NannyHubProblem.photoUnreadable,
        ),
      ),
    );
    final jpeg = await PhotoCompressor.compress(aPhoto(width: 20, height: 10));
    expect(jpeg, isNotEmpty);
  });
}
