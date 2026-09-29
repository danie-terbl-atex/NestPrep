import '../data/photo_compressor.dart';
import '../data/photo_source.dart';
import '../model/compressed_photo.dart';

/// Takes or chooses a photo and compresses it to what the rules keep — the
/// one path both the before photo and the after photo come in by
/// (home-care ADR-0003, `ENG-01`).
final class PhotoIntake {
  const PhotoIntake({required this._source, required this._compressor});

  final PhotoSource _source;
  final PhotoCompressor _compressor;

  /// The photo ready to store, or null when the person backed out. A refused
  /// camera or an unreadable picture is a `HomeCareFailure`.
  Future<CompressedPhoto?> take(PhotoOrigin origin) async {
    final original = await _source.pick(origin);
    if (original == null) return null;
    return _compressor.compress(original);
  }
}
