import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_limits.dart';

/// `FE-04`/`BE-20`: the size and type limits are the **rules'**, and the client
/// keeps a copy only so nobody waits for a 20 MiB upload to be refused.
///
/// A copy is a thing that drifts. The day the cap moves in `storage.rules` and
/// not here, the app refuses files the household is allowed to keep — silently,
/// with copy that reads as though the rule said so. The day it moves here and
/// not there, somebody watches a whole file upload and then be rejected.
///
/// So this reads both rules files rather than a note about them, the way
/// `emulator_ports.test.ts` reads `firebase.json`.
void main() {
  final repoRoot = Directory.current.parent;
  // The documents' limits are their own Storage partial (foundation
  // ADR-0013): the photo features keep caps of their own in theirs, which
  // their own contract tests hold to their numbers.
  final storageRules = File(
    '${repoRoot.path}/rules/storage/shared/document_files.rules',
  );
  final firestoreRules = File('${repoRoot.path}/firestore.rules');

  String read(File file) => file.readAsStringSync();

  /// Every `'type/subtype'` in a rules file, which is how both spell the list.
  Set<String> contentTypesIn(String source) => {
    for (final match in RegExp(
      r"'(application/[a-z-]+|image/[a-z0-9]+)'",
    ).allMatches(source))
      match.group(1)!,
  };

  /// Every `<n> * 1024 * 1024` in a rules file, as bytes.
  Set<int> byteCapsIn(String source) => {
    for (final match in RegExp(r'(\d+) \* 1024 \* 1024').allMatches(source))
      int.parse(match.group(1)!) * 1024 * 1024,
  };

  test('both rules files are where this test thinks they are', () {
    expect(
      storageRules.existsSync(),
      isTrue,
      reason:
          'if the documents\' Storage partial moved, this contract lost its home — point the '
          'test at the new one rather than deleting it',
    );
    expect(firestoreRules.existsSync(), isTrue);
  });

  test('the parser can still see what it is checking', () {
    // Without this, a change to how the rules spell a list would leave every
    // check below passing against an empty set.
    expect(contentTypesIn(read(storageRules)), isNotEmpty);
    expect(byteCapsIn(read(storageRules)), isNotEmpty);
  });

  test('storage.rules keeps exactly the types the app offers', () {
    expect(
      contentTypesIn(read(storageRules)),
      DocumentLimits.keptContentTypes,
      reason:
          'the picker and the rule must agree, or one of them is lying to '
          'somebody holding a phone (`FE-04`)',
    );
  });

  test('firestore.rules records exactly the same types', () {
    // The metadata row's type is a label, but a row describing something the
    // bytes could never have been is a row nobody can act on.
    expect(
      contentTypesIn(read(firestoreRules)),
      DocumentLimits.keptContentTypes,
    );
  });

  test('the cap in storage.rules is the cap the app refuses at', () {
    expect(byteCapsIn(read(storageRules)), {DocumentLimits.maxSizeBytes});
  });

  test('and firestore.rules carries the same number', () {
    expect(byteCapsIn(read(firestoreRules)), {DocumentLimits.maxSizeBytes});
  });

  test('the name cap in the rules is the one the keyboard stops at', () {
    final declared = RegExp(r'value\.size\(\) <= (\d+)')
        .firstMatch(read(firestoreRules));
    expect(declared, isNotNull, reason: 'the name rule changed shape');
    expect(int.parse(declared!.group(1)!), DocumentLimits.nameMaxLength);
  });

  group('what the app refuses before it sends anything', () {
    test('accepts a kept type inside the cap', () {
      expect(
        DocumentLimits.problemWith(
          contentType: 'application/pdf',
          sizeBytes: DocumentLimits.maxSizeBytes,
        ),
        isNull,
      );
    });

    test('refuses a byte past the cap', () {
      expect(
        DocumentLimits.problemWith(
          contentType: 'application/pdf',
          sizeBytes: DocumentLimits.maxSizeBytes + 1,
        )?.name,
        'fileTooLarge',
      );
    });

    test('refuses an empty file, which is nobody"s document', () {
      expect(
        DocumentLimits.problemWith(
          contentType: 'application/pdf',
          sizeBytes: 0,
        )?.name,
        'fileTooLarge',
      );
    });

    test('refuses a type before it judges the size', () {
      expect(
        DocumentLimits.problemWith(
          contentType: 'application/zip',
          sizeBytes: 1,
        )?.name,
        'unsupportedType',
      );
    });

    test('refuses a device that would not say what the file is', () {
      expect(
        DocumentLimits.problemWith(contentType: '', sizeBytes: 1)?.name,
        'unsupportedType',
      );
    });
  });

  test('every previewable type is one the household may keep', () {
    expect(
      DocumentLimits.keptContentTypes,
      containsAll(DocumentLimits.previewableContentTypes),
    );
    expect(DocumentLimits.isPreviewable('application/pdf'), isFalse);
    expect(DocumentLimits.isPreviewable('image/png'), isTrue);
  });
}
