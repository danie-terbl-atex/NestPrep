import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/home_care/model/home_care_photo.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/photos/compressed_photo.dart';
import 'package:nestprep/shared/photos/jpeg_compressor.dart';

/// What leaves the phone when somebody adds a photo of the home — a nanny-hub
/// spot or a cleaning job's before and after (`ENG-01`; nanny-hub ADR-0003,
/// home-care ADR-0003): upright, no longer than 1600 px on its long edge, a
/// JPEG, and carrying nothing about where it was taken.
void main() {
  Uint8List photo(
    int width,
    int height, {
    bool asPng = false,
    bool gps = false,
  }) {
    final image = img.Image(width: width, height: height);
    // Gradients with a little texture — closer to a wall or a worktop than
    // flat colour is, so the encoder has something real to compress.
    for (final pixel in image) {
      pixel
        ..r = pixel.x * 255 ~/ width
        ..g = pixel.y * 255 ~/ height
        ..b = ((pixel.x ~/ 40) + (pixel.y ~/ 40)).isEven ? 90 : 140;
    }
    if (gps) {
      image.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(26, 1);
      image.exif.imageIfd['Make'] = img.IfdValueAscii('Phone');
    }
    return Uint8List.fromList(
      asPng ? img.encodePng(image) : img.encodeJpg(image),
    );
  }

  const failing = JpegCompressor(
    maxBytes: 100,
    unreadable: HomeCareFailure(HomeCareProblem.photoUnreadable),
    tooLarge: HomeCareFailure(HomeCareProblem.photoTooLarge),
  );

  test('scales a landscape photo to a 1600 px long edge', () {
    final compressed = JpegCompressor.compressNow(photo(3200, 2400))!;
    expect(compressed.width, JpegCompressor.longEdge);
    expect(compressed.height, 1200);
    expect(img.decodeJpg(compressed.bytes)!.width, JpegCompressor.longEdge);
  });

  test('scales a portrait photo by its height', () {
    final compressed = JpegCompressor.compressNow(photo(1000, 2000))!;
    expect((compressed.width, compressed.height), (800, 1600));
  });

  test('leaves a small photo its size, and makes it a JPEG', () {
    final compressed = JpegCompressor.compressNow(
      photo(640, 480, asPng: true),
    )!;
    expect((compressed.width, compressed.height), (640, 480));
    expect(compressed.bytes.sublist(0, 2), [0xFF, 0xD8]);
  });

  test('carries no metadata out — not where it was taken, not the phone', () {
    final source = photo(800, 600, gps: true);
    expect(img.decodeJpg(source)!.exif.isEmpty, isFalse);
    final compressed = JpegCompressor.compressNow(source)!;
    expect(img.decodeJpg(compressed.bytes)!.exif.isEmpty, isTrue);
  });

  test('ends up well under what either feature keeps', () {
    final compressed = JpegCompressor.compressNow(photo(4000, 3000))!;
    expect(compressed.bytes.length, lessThan(2 * 1024 * 1024 ~/ 4));
  });

  test('is nothing at all when the bytes are not a picture', () {
    expect(JpegCompressor.compressNow(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('off the main isolate, compresses the same way', () async {
    final compressed = await HomeCarePhoto.compressor.compress(
      photo(2000, 1000),
    );
    expect((compressed.width, compressed.height), (1600, 800));
    expect(CompressedPhoto.contentType, 'image/jpeg');
  });

  test('and refuses unreadable bytes in the feature’s words', () async {
    await expectLater(
      HomeCarePhoto.compressor.compress(Uint8List.fromList([1, 2, 3])),
      throwsA(
        isA<HomeCareFailure>().having(
          (failure) => failure.problem,
          'problem',
          HomeCareProblem.photoUnreadable,
        ),
      ),
    );
  });

  test('and refuses a photo past the feature’s cap in its words', () async {
    await expectLater(
      failing.compress(photo(400, 300)),
      throwsA(
        isA<HomeCareFailure>().having(
          (failure) => failure.problem,
          'problem',
          HomeCareProblem.photoTooLarge,
        ),
      ),
    );
  });

  test('names the photo a job records with its size', () {
    final named = CompressedPhoto(
      bytes: Uint8List(1),
      width: 3,
      height: 4,
    ).named('after-2');
    expect((named.photoId, named.width, named.height), ('after-2', 3, 4));
    expect(named.aspectRatio, 0.75);
  });
}
