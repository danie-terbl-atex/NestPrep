import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../failure/app_failure.dart';
import 'compressed_photo.dart';
import 'photo_compressor.dart';

/// Turns whatever the camera or gallery handed over into a photo a feature's
/// storage rule keeps — the one pipeline every household photo leaves the
/// phone by (`ENG-01`; nanny-hub ADR-0003, home-care ADR-0003).
///
/// Every photo is turned upright, scaled so its long edge is at most
/// [longEdge], **stripped of its metadata**, and re-encoded as a JPEG. The
/// stripping is the point: a phone photo of the linen cupboard or of a stain
/// on the carpet carries the GPS position of the house it was taken in. The
/// documents scanner keeps what it reads because a scan is a copy of a
/// document; this is a picture of a home. A 12-megapixel photo of 4–8 MB
/// leaves as a few hundred kilobytes.
///
/// The work runs in a background isolate, because decoding a large photo on
/// the UI thread is a frozen screen. What each feature brings is its own cap
/// — its rule's — and its own words for the two ways a photo is refused.
final class JpegCompressor implements PhotoCompressor {
  const JpegCompressor({
    required this.maxBytes,
    required this.unreadable,
    required this.tooLarge,
  });

  static const longEdge = 1600;
  static const quality = 78;

  /// The most the feature's storage rule keeps of one photo.
  final int maxBytes;

  /// Thrown when the bytes are not a picture the app can read.
  final AppFailure unreadable;

  /// Thrown when, even compressed, the photo is past [maxBytes].
  final AppFailure tooLarge;

  /// The compressed photo, made off the main isolate; [unreadable] or
  /// [tooLarge] when it cannot be kept.
  @override
  Future<CompressedPhoto> compress(Uint8List original) async {
    final photo = await Isolate.run(() => compressNow(original));
    if (photo == null) throw unreadable;
    if (photo.bytes.length > maxBytes) throw tooLarge;
    return photo;
  }

  /// The pipeline itself, on whatever isolate calls it — what the background
  /// isolate runs, and what a test calls directly. Null when the bytes are not
  /// a picture; the caller turns that into its feature's words.
  static CompressedPhoto? compressNow(Uint8List original) {
    final decoded = _decode(original);
    if (decoded == null) return null;
    // A phone stores "which way up" as a tag rather than turning the pixels;
    // the tag does not survive the re-encode, so the turn is made now.
    var upright = img.bakeOrientation(decoded);
    final isWide = upright.width >= upright.height;
    final longest = isWide ? upright.width : upright.height;
    if (longest > longEdge) {
      upright = img.copyResize(
        upright,
        width: isWide ? longEdge : null,
        height: isWide ? null : longEdge,
        interpolation: img.Interpolation.average,
      );
    }
    upright.exif = img.ExifData();
    return CompressedPhoto(
      bytes: img.encodeJpg(upright, quality: quality),
      width: upright.width,
      height: upright.height,
    );
  }

  /// The picture in [original], or null when it is not one. The `image`
  /// package reads a file shorter than a format's signature — or a truncated
  /// one — by running off the end of it, and some decoders throw on bytes
  /// that are not theirs rather than saying no. Every one of those is the same
  /// answer, which the caller says in words (`ENG-10`).
  static img.Image? _decode(Uint8List original) {
    try {
      return img.findDecoderForData(original)?.decode(original);
    } on Exception {
      return null;
    } on RangeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}
