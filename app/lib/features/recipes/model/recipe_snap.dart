import 'dart:typed_data';

/// One photo or screenshot of a recipe, cut into the overlapping JPEG parts
/// the model reads (recipes ADR-0010). It lives in memory until it is read.
final class RecipeSnap {
  const RecipeSnap({required this.parts, required this.thumbnail, this.whole});

  final List<Uint8List> parts;
  final Uint8List thumbnail;

  /// The photo in one piece, for a read of this photo alone. Null when it is
  /// too long to be read that way.
  final Uint8List? whole;

  /// The server's `MAX_SNAP_PHOTOS`, `MAX_SNAP_PARTS` and
  /// `MAX_SNAP_PART_BYTES`. Every part at its largest still fits one request.
  static const maxPhotos = 8;
  static const maxParts = 40;
  static const maxPartBytes = 160 * 1024;
  static const maxWholeBytes = 1024 * 1024;
}
