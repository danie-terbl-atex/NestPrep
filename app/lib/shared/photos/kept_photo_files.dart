import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Pictures kept on the phone by their Storage path, in memory and in one
/// folder of the app's support directory: a lunch photo (lunch-box ADR-0015)
/// and a recipe's (recipes ADR-0003 §4) are each named for what they show
/// and never change, so each is fetched once and read from here after.
final class KeptPhotoFiles {
  KeptPhotoFiles(this._folderName);

  final String _folderName;
  final _bytes = <String, Uint8List>{};

  /// The picture at [path]: from memory, else from the folder, else from
  /// [orFetch] — kept when it answers. A failure of [orFetch] is the
  /// caller's to handle.
  Future<Uint8List?> read(
    String path, {
    required Future<Uint8List?> Function() orFetch,
  }) async {
    final kept = _bytes[path];
    if (kept != null) return kept;
    final file = File('${(await _folder()).path}/${path.replaceAll('/', '_')}');
    if (await file.exists()) return _bytes[path] = await file.readAsBytes();
    final bytes = await orFetch();
    if (bytes == null) return null;
    await file.writeAsBytes(bytes, flush: true);
    return _bytes[path] = bytes;
  }

  Future<Directory> _folder() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/$_folderName').create(recursive: true);
  }
}
