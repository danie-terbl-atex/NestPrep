import 'dart:isolate';
import 'dart:typed_data';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/media/jpeg_shrinker.dart';
import '../model/nanny_limits.dart';

/// Every hub photo on its way out of the phone: turned upright, scaled so its
/// long edge is at most [maxEdge], **stripped of its metadata**, and
/// re-encoded as a JPEG (nanny-hub ADR-0003).
///
/// The stripping is the reason this is not the documents scanner's pipeline
/// (`ENG-25`): a phone photo of the linen cupboard carries the GPS position of
/// the house it was taken in, and a photo of a child carries it too. The
/// scanner keeps what it reads because a scan is a copy of a document; a hub
/// photo is a picture of a home. A 12-megapixel photo of 4–8 MB leaves as a
/// few hundred kilobytes — well under what the rules keep.
///
/// The work runs in a background isolate, because decoding a large photo on
/// the UI thread is a frozen screen.
abstract final class PhotoCompressor {
  static const maxEdge = 1600;
  static const jpegQuality = 78;

  /// The compressed JPEG; a `NannyHubFailure` when the bytes are not a picture
  /// or are still too big to keep.
  static Future<Uint8List> compress(Uint8List bytes) async {
    final jpeg = await Isolate.run(() => compressNow(bytes));
    if (jpeg == null) {
      throw const NannyHubFailure(NannyHubProblem.photoUnreadable);
    }
    if (jpeg.length > NannyLimits.photoBytes) {
      throw const NannyHubFailure(NannyHubProblem.photoTooLarge);
    }
    return jpeg;
  }

  /// The pipeline itself, on whatever thread calls it. Null when the bytes are
  /// not an image — an isolate cannot carry an `AppFailure` back.
  static Uint8List? compressNow(Uint8List bytes) =>
      JpegShrinker.shrink(bytes, maxEdge: maxEdge, quality: jpegQuality);
}
