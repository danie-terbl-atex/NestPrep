import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/home_care/data/photo_compressor.dart';
import 'package:nestprep/features/home_care/model/compressed_photo.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// What reaches Storage is a JPEG no larger than 1600 px on its long edge
/// (home-care ADR-0003) — whatever the camera or gallery handed over.
void main() {
  Uint8List photo(int width, int height, {bool asPng = false}) {
    final image = img.Image(width: width, height: height);
    // Gradients with a little texture — closer to a wall or a worktop than
    // flat colour is, so the encoder has something real to compress.
    for (final pixel in image) {
      pixel
        ..r = pixel.x * 255 ~/ width
        ..g = pixel.y * 255 ~/ height
        ..b = ((pixel.x ~/ 40) + (pixel.y ~/ 40)).isEven ? 90 : 140;
    }
    return Uint8List.fromList(
      asPng ? img.encodePng(image) : img.encodeJpg(image),
    );
  }

  test('scales a landscape photo to a 1600 px long edge', () {
    final compressed = JpegPhotoCompressor.compressNow(photo(3200, 2400));
    expect(compressed.width, CompressedPhoto.longEdge);
    expect(compressed.height, 1200);
    expect(img.decodeJpg(compressed.bytes), isNotNull);
  });

  test('scales a portrait photo by its height', () {
    final compressed = JpegPhotoCompressor.compressNow(photo(1000, 2000));
    expect(compressed.height, CompressedPhoto.longEdge);
    expect(compressed.width, 800);
  });

  test('leaves a small photo its size, and makes it a JPEG', () {
    final compressed = JpegPhotoCompressor.compressNow(
      photo(640, 480, asPng: true),
    );
    expect((compressed.width, compressed.height), (640, 480));
    expect(img.decodeJpg(compressed.bytes), isNotNull);
  });

  test('ends up well under what the rules keep', () {
    final compressed = JpegPhotoCompressor.compressNow(photo(4000, 3000));
    expect(compressed.fitsTheRules, isTrue);
    expect(compressed.bytes.length, lessThan(CompressedPhoto.maxBytes ~/ 4));
  });

  test('refuses bytes that are no picture, in words', () {
    expect(
      () => JpegPhotoCompressor.compressNow(Uint8List.fromList([1, 2, 3])),
      throwsA(
        isA<HomeCareFailure>().having(
          (failure) => failure.problem,
          'problem',
          HomeCareProblem.photoUnreadable,
        ),
      ),
    );
  });

  test('does the same off the main isolate', () async {
    final compressed = await const JpegPhotoCompressor().compress(
      photo(2000, 1000),
    );
    expect((compressed.width, compressed.height), (1600, 800));
  });

  test('names the photo it becomes with its size', () {
    final named = CompressedPhoto(
      bytes: Uint8List(1),
      width: 3,
      height: 4,
    ).named('after-2');
    expect((named.photoId, named.width, named.height), ('after-2', 3, 4));
    expect(named.aspectRatio, 0.75);
  });
}
