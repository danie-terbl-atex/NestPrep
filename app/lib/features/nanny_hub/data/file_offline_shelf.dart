import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'offline_shelf.dart';

/// The shelf as files in the app's private support folder — not the cache
/// folder, which the phone may empty when it is short of space, exactly when
/// a carer is out of signal (nanny-hub ADR-0007). One folder per household:
///
///     nanny_offline/{householdId}/photos/{photoId}.jpg
///     nanny_offline/{householdId}/saved_at
final class FileOfflineShelf implements OfflineShelf {
  FileOfflineShelf({Future<Directory> Function()? root})
    : _root = root ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _root;

  /// A household id and a photo id are both generated, never typed; this
  /// keeps anything else from becoming a path.
  static final _safeName = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  Future<Directory> _household(String householdId) async {
    final root = await _root();
    return Directory('${root.path}/nanny_offline/${_checked(householdId)}');
  }

  Future<File> _photo(String householdId, String photoId) async {
    final folder = await _household(householdId);
    return File('${folder.path}/photos/${_checked(photoId)}.jpg');
  }

  Future<File> _stamp(String householdId) async {
    final folder = await _household(householdId);
    return File('${folder.path}/saved_at');
  }

  static String _checked(String name) {
    if (!_safeName.hasMatch(name)) {
      throw ArgumentError.value(name, 'name', 'not a generated id');
    }
    return name;
  }

  @override
  Future<Uint8List?> readPhoto({
    required String householdId,
    required String photoId,
  }) => _guarded(() async {
    final file = await _photo(householdId, photoId);
    return await file.exists() ? await file.readAsBytes() : null;
  });

  @override
  Future<bool> hasPhoto({
    required String householdId,
    required String photoId,
  }) => _guarded(() async => (await _photo(householdId, photoId)).exists());

  @override
  Future<void> keepPhoto({
    required String householdId,
    required String photoId,
    required Uint8List jpeg,
  }) => _guarded(() async {
    final file = await _photo(householdId, photoId);
    await file.parent.create(recursive: true);
    // Written aside and moved into place, so a photo cut off half-way by a
    // closing app is never read back as a broken picture.
    final partial = File('${file.path}.partial');
    await partial.writeAsBytes(jpeg, flush: true);
    await partial.rename(file.path);
  });

  @override
  Future<DateTime?> savedAt(String householdId) => _guarded(() async {
    final stamp = await _stamp(householdId);
    if (!await stamp.exists()) return null;
    return DateTime.tryParse(await stamp.readAsString())?.toUtc();
  });

  @override
  Future<void> markSaved(String householdId, DateTime at) => _guarded(() async {
    final stamp = await _stamp(householdId);
    await stamp.parent.create(recursive: true);
    await stamp.writeAsString(at.toUtc().toIso8601String(), flush: true);
  });

  @override
  Future<void> clear(String householdId) => _guarded(() async {
    final folder = await _household(householdId);
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  /// A phone that will not read or write its own folder is out of space or
  /// locked down; the hub says it could not save, and works on without it.
  Future<T> _guarded<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on FileSystemException catch (error) {
      AppLog.failure('offline shelf', code: 'filesystem', error: error);
      throw const NannyHubFailure(NannyHubProblem.cannotSaveOffline);
    }
  }
}
