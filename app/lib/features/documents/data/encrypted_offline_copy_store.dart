import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../model/offline_copy.dart';
import 'offline_copy_cipher.dart';
import 'offline_copy_store.dart';
import 'offline_key_vault.dart';

/// The offline copies on disk (documents ADR-0007):
///
///     <support>/offline_documents/<uid>/index.bin     the list, sealed
///     <support>/offline_documents/<uid>/<key>.bin     one copy, sealed
///
/// Both sealed with the account's key from [OfflineKeyVault], so neither a
/// document nor its name is readable from the file system or a backup (and
/// `offline_documents/` is excluded from Android's backups besides). Writes
/// are serialised, and the index is replaced by rename, so a crash mid-save
/// leaves the old list or the new one — never half of either.
final class EncryptedOfflineCopyStore implements OfflineCopyStore {
  EncryptedOfflineCopyStore({
    required OfflineKeyVault keyVault,
    required Future<Directory> Function() supportDirectory,
  }) : _keys = keyVault,
       _support = supportDirectory;

  /// Named in `res/xml/nestprep_backup_rules.xml` and the extraction rules;
  /// `offline_backup_rules_test.dart` reads both.
  static const folderName = 'offline_documents';
  static const _index = 'index.bin';

  final OfflineKeyVault _keys;
  final Future<Directory> Function() _support;
  Future<void> _queue = Future.value();

  Future<Directory> _root() async =>
      Directory('${(await _support()).path}/$folderName');

  Future<Directory> _folderOf(String uid) async =>
      Directory('${(await _root()).path}/${_safe(uid)}');

  @override
  Future<List<OfflineCopy>> list(String uid) => _serial(() => _readIndex(uid));

  @override
  Future<void> save(String uid, OfflineCopy copy, Uint8List bytes) =>
      _serial(() async {
        final key = await _keys.keyFor(uid);
        final folder = await _folderOf(uid);
        await folder.create(recursive: true);
        await _replace(
          File('${folder.path}/${copy.key}.bin'),
          await OfflineCopyCipher.seal(key, bytes),
        );
        final others = (await _readIndex(uid)).where((c) => c.key != copy.key);
        await _writeIndex(uid, [copy, ...others]);
      });

  @override
  Future<Uint8List> read(String uid, OfflineCopy copy) => _serial(() async {
    final file = File('${(await _folderOf(uid)).path}/${copy.key}.bin');
    if (!file.existsSync()) throw const NotFoundFailure();
    return OfflineCopyCipher.open(
      await _keys.keyFor(uid),
      await file.readAsBytes(),
    );
  });

  @override
  Future<void> remove(String uid, Iterable<OfflineCopy> copies) =>
      _serial(() async {
        final going = {for (final copy in copies) copy.key};
        if (going.isEmpty) return;
        final folder = await _folderOf(uid);
        for (final key in going) {
          final file = File('${folder.path}/$key.bin');
          if (file.existsSync()) await file.delete();
        }
        final kept = (await _readIndex(uid))
            .where((copy) => !going.contains(copy.key));
        await _writeIndex(uid, kept.toList());
      });

  @override
  Future<void> keepOnly(String? uid) => _serial(() async {
    final keep = uid == null ? null : _safe(uid);
    final root = await _root();
    if (root.existsSync()) {
      await for (final entry in root.list()) {
        if (entry.path.split('/').last != keep) {
          await entry.delete(recursive: true);
        }
      }
    }
    for (final account in await _keys.accounts()) {
      if (account != uid) await _keys.forget(account);
    }
  });

  /// The list, or none when there is no index yet. An index that will not
  /// open is a list nobody can use: its copies are deleted with it, and the
  /// person saves them again.
  Future<List<OfflineCopy>> _readIndex(String uid) async {
    final folder = await _folderOf(uid);
    final file = File('${folder.path}/$_index');
    if (!file.existsSync()) return const [];
    try {
      final clear = await OfflineCopyCipher.open(
        await _keys.keyFor(uid),
        await file.readAsBytes(),
      );
      return _parseIndex(utf8.decode(clear));
    } on DocumentFailure catch (failure) {
      // A keystore that is briefly unavailable is not a broken index.
      if (failure.problem == DocumentProblem.offlineCopyUnreadable) {
        await folder.delete(recursive: true);
      }
      rethrow;
    } on FormatException {
      await folder.delete(recursive: true);
      throw const DocumentFailure(DocumentProblem.offlineCopyUnreadable);
    }
  }

  List<OfflineCopy> _parseIndex(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! List<Object?>) {
      throw const FormatException('the offline index is not a list');
    }
    return [
      for (final entry in decoded)
        if (entry is Map<String, Object?>) OfflineCopy.fromJson(entry),
    ];
  }

  Future<void> _writeIndex(String uid, List<OfflineCopy> copies) async {
    final folder = await _folderOf(uid);
    final text = jsonEncode([for (final copy in copies) copy.toJson()]);
    await _replace(
      File('${folder.path}/$_index'),
      await OfflineCopyCipher.seal(await _keys.keyFor(uid), utf8.encode(text)),
    );
  }

  /// Writes beside, then renames over: a crash leaves one whole file.
  Future<void> _replace(File file, Uint8List bytes) async {
    final next = File('${file.path}.next');
    await next.writeAsBytes(bytes, flush: true);
    await next.rename(file.path);
  }

  /// One operation at a time: a save and a removal racing over the index
  /// would each write back a list missing the other's change.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => _translated(action));
    _queue = result.then<void>((_) {}, onError: _reportedToTheCaller);
    return result;
  }

  /// A disk that will not read or write is the phone's problem, said in the
  /// app's words rather than as a file system error.
  static Future<T> _translated<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FileSystemException catch (error) {
      AppLog.failure('offline copies disk', code: 'io', error: error);
      throw const DocumentFailure(DocumentProblem.offlineStorageUnavailable);
    }
  }

  /// The queue only waits for an operation to finish; its failure has
  /// already gone to whoever called it, through `result`.
  static void _reportedToTheCaller(Object error) {}

  static String _safe(String uid) =>
      uid.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
}
