import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../shared/failure/app_failure.dart';
import 'guarded_web_fetch.dart';

abstract interface class RecipeImageFetcher {
  /// The picture's bytes, or null for any reason at all: a page's picture is
  /// never worth failing an import for.
  Future<Uint8List?> fetch(String url);
}

final class HttpRecipeImageFetcher implements RecipeImageFetcher {
  const HttpRecipeImageFetcher(this._fetch);

  final GuardedWebFetch _fetch;

  static const _maxBytes = 8 * 1024 * 1024;

  /// About 160 MB once decoded. The largest thing the shared pipeline could be
  /// handed without a stranger's small file running the phone out of memory.
  static const maxPixels = 40 * 1000 * 1000;

  static bool _isImage(String? contentType) {
    final type = contentType?.toLowerCase() ?? 'image/';
    return type.startsWith('image/') || type.contains('octet-stream');
  }

  @override
  Future<Uint8List?> fetch(String url) async {
    try {
      final file = await _fetch.get(
        url,
        maxBytes: _maxBytes,
        accept: 'image/*',
        accepts: _isImage,
      );
      final bytes = file.bytes;
      return await Isolate.run(() => isSafeToDecode(bytes)) ? bytes : null;
    } on AppFailure {
      return null;
    }
  }

  /// Reads the file's header only, because its size is the thing in doubt.
  static bool isSafeToDecode(Uint8List bytes) {
    try {
      final info = img.findDecoderForData(bytes)?.startDecode(bytes);
      if (info == null || info.width <= 0 || info.height <= 0) return false;
      return info.width * info.height * max(info.numFrames, 1) <= maxPixels;
    } on Object {
      return false;
    }
  }
}
