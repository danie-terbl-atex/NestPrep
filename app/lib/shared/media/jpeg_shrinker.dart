import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A phone photo made fit to leave the phone: turned upright, scaled so its
/// long edge is at most [maxEdge], **stripped of its metadata** (a photo of a
/// home carries the home's GPS position), and re-encoded as a JPEG.
///
/// Shared by the nanny hub's photos (nanny-hub ADR-0003) and a snapped school
/// letter (calendar ADR-0005) — the second use, so it lives here (`ENG-02`).
/// Pure and synchronous: callers run it in an isolate, because decoding a
/// large photo on the UI thread is a frozen screen.
abstract final class JpegShrinker {
  /// The JPEG, or null when [bytes] are not a picture — an isolate cannot
  /// carry a feature's own failure back, so the caller names it.
  static Uint8List? shrink(
    Uint8List bytes, {
    required int maxEdge,
    required int quality,
  }) {
    final decoded = _decode(bytes);
    if (decoded == null) return null;
    var upright = img.bakeOrientation(decoded);
    final isWide = upright.width >= upright.height;
    final longEdge = isWide ? upright.width : upright.height;
    if (longEdge > maxEdge) {
      upright = img.copyResize(
        upright,
        width: isWide ? maxEdge : null,
        height: isWide ? null : maxEdge,
        interpolation: img.Interpolation.average,
      );
    }
    upright.exif = img.ExifData();
    return img.encodeJpg(upright, quality: quality);
  }

  /// The picture in [bytes], or null when they are not one. The `image`
  /// package reads a file shorter than a format's signature — or a truncated
  /// one — by running off the end of it, which is the same answer: not a
  /// picture. The caller turns null into its own words (`ENG-10`).
  static img.Image? _decode(Uint8List bytes) {
    try {
      return img.findDecoderForData(bytes)?.decode(bytes);
    } on RangeError {
      return null;
    }
  }
}
