import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/data/encrypted_offline_copy_store.dart';
import 'package:nestprep/features/documents/data/offline_copy_cipher.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_document_tools.dart';

/// Offline copies at rest (documents ADR-0007), against a real disk: every
/// byte and every name is sealed, a tampered or foreign file is refused, and
/// signing out leaves nothing behind — neither the files nor their key.
void main() {
  late Directory support;
  late InMemoryOfflineKeyVault keys;
  late EncryptedOfflineCopyStore store;

  setUp(() {
    support = Directory.systemTemp.createTempSync('offline_copies_');
    keys = InMemoryOfflineKeyVault();
    store = EncryptedOfflineCopyStore(
      keyVault: keys,
      supportDirectory: () async => support,
    );
  });

  tearDown(() => support.deleteSync(recursive: true));

  final card = Uint8List.fromList(utf8.encode('%PDF the medical aid card'));

  /// Every byte the store has written for [uid], in one string.
  String everythingOnDiskFor(String uid) {
    final folder = Directory(
      '${support.path}/${EncryptedOfflineCopyStore.folderName}/$uid',
    );
    return folder
        .listSync()
        .whereType<File>()
        .map((file) => latin1.decode(file.readAsBytesSync()))
        .join();
  }

  group('the cipher', () {
    test('opens what it sealed, and nothing else', () async {
      final key = OfflineCopyCipher.newKey();
      final sealed = await OfflineCopyCipher.seal(key, card);
      expect(sealed, isNot(card));
      expect(await OfflineCopyCipher.open(key, sealed), card);

      final tampered = Uint8List.fromList(sealed)..[sealed.length - 1] ^= 1;
      await expectLater(
        OfflineCopyCipher.open(key, tampered),
        throwsA(
          isA<DocumentFailure>().having(
            (failure) => failure.problem,
            'problem',
            DocumentProblem.offlineCopyUnreadable,
          ),
        ),
      );
      await expectLater(
        OfflineCopyCipher.open(OfflineCopyCipher.newKey(), sealed),
        throwsA(isA<DocumentFailure>()),
      );
      await expectLater(
        OfflineCopyCipher.open(key, [1, 2, 3]),
        throwsA(isA<DocumentFailure>()),
      );
    });

    test(
      'seals the same bytes differently every time — a fresh nonce',
      () async {
        final key = OfflineCopyCipher.newKey();
        expect(key, hasLength(OfflineCopyCipher.keyLength));
        expect(
          await OfflineCopyCipher.seal(key, card),
          isNot(await OfflineCopyCipher.seal(key, card)),
        );
      },
    );
  });

  group('the store', () {
    test('keeps a copy and gives the same bytes back', () async {
      final copy = anOfflineCopy('card', ownerMemberId: 'm-kid');
      await store.save('uid-sam', copy, card);

      expect(await store.list('uid-sam'), [copy]);
      expect(await store.read('uid-sam', copy), card);
    });

    test('writes neither a document nor its name in the clear', () async {
      final copy = anOfflineCopy('card');
      await store.save('uid-sam', copy, card);

      final disk = everythingOnDiskFor('uid-sam');
      expect(disk, isNot(contains('medical aid')));
      expect(disk, isNot(contains(copy.name)));
    });

    test(
      'lists newest first, and saving again replaces rather than adds',
      () async {
        await store.save('uid-sam', anOfflineCopy('a'), card);
        await store.save('uid-sam', anOfflineCopy('b'), card);
        await store.save('uid-sam', anOfflineCopy('a'), card);

        final listed = await store.list('uid-sam');
        expect(listed.map((copy) => copy.documentId), ['a', 'b']);
      },
    );

    test(
      'removes a copy and its file; removing one not kept is fine',
      () async {
        final copy = anOfflineCopy('card');
        await store.save('uid-sam', copy, card);
        await store.remove('uid-sam', [copy, anOfflineCopy('never-kept')]);

        expect(await store.list('uid-sam'), isEmpty);
        await expectLater(
          store.read('uid-sam', copy),
          throwsA(isA<NotFoundFailure>()),
        );
      },
    );

    test('keeps each account apart', () async {
      await store.save('uid-sam', anOfflineCopy('a'), card);
      await store.save('uid-alex', anOfflineCopy('b'), card);

      expect((await store.list('uid-sam')).map((c) => c.documentId), ['a']);
      expect((await store.list('uid-alex')).map((c) => c.documentId), ['b']);
    });

    test('signing in as somebody else deletes every other account — files '
        'and key', () async {
      await store.save('uid-sam', anOfflineCopy('a'), card);
      await store.save('uid-alex', anOfflineCopy('b'), card);

      await store.keepOnly('uid-alex');

      expect(keys.keys.keys, ['uid-alex']);
      expect(
        Directory(
          '${support.path}/${EncryptedOfflineCopyStore.folderName}/uid-sam',
        ).existsSync(),
        isFalse,
      );
      expect(await store.list('uid-alex'), hasLength(1));
    });

    test('signing out deletes everything', () async {
      await store.save('uid-sam', anOfflineCopy('a'), card);
      await store.keepOnly(null);

      expect(keys.keys, isEmpty);
      expect(await store.list('uid-sam'), isEmpty);
    });

    test('a copy whose key is gone cannot be read, and its list is dropped '
        'rather than guessed at', () async {
      await store.save('uid-sam', anOfflineCopy('a'), card);
      // As after a restore onto a phone without the keystore entry.
      keys.keys['uid-sam'] = List<int>.filled(32, 7);

      await expectLater(
        store.list('uid-sam'),
        throwsA(
          isA<DocumentFailure>().having(
            (failure) => failure.problem,
            'problem',
            DocumentProblem.offlineCopyUnreadable,
          ),
        ),
      );
      expect(await store.list('uid-sam'), isEmpty);
    });

    test(
      'a keystore that will not answer is not mistaken for a broken list',
      () async {
        await store.save('uid-sam', anOfflineCopy('a'), card);
        keys.failWith = const DocumentFailure(
          DocumentProblem.offlineStorageUnavailable,
        );
        await expectLater(
          store.list('uid-sam'),
          throwsA(isA<DocumentFailure>()),
        );

        keys.failWith = null;
        expect(await store.list('uid-sam'), hasLength(1));
      },
    );
  });

  group('Android backups leave the copies behind', () {
    test('both backup rule files exclude the folder and the keystore', () {
      for (final name in [
        'nestprep_backup_rules.xml',
        'nestprep_data_extraction_rules.xml',
      ]) {
        final rules = File(
          'android/app/src/main/res/xml/$name',
        ).readAsStringSync();
        expect(
          rules,
          contains('path="${EncryptedOfflineCopyStore.folderName}/"'),
          reason: name,
        );
        expect(rules, contains('FlutterSecureStorage.xml'), reason: name);
      }
    });

    test('and the manifest points at them', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        manifest,
        contains('android:fullBackupContent="@xml/nestprep_backup_rules"'),
      );
      expect(
        manifest,
        contains(
          'android:dataExtractionRules="@xml/nestprep_data_extraction_rules"',
        ),
      );
    });
  });
}
