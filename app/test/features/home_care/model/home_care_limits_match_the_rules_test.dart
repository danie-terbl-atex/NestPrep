import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/data/storage_job_photo_store.dart';
import 'package:nestprep/features/home_care/model/home_care_photo.dart';
import 'package:nestprep/shared/photos/compressed_photo.dart';

/// The photo limits are `storage.rules`' (home-care ADR-0003); the app keeps
/// a copy only so a photo too big is refused before anybody waits for the
/// upload. This reads the home-care Storage partial itself (foundation
/// ADR-0013).
void main() {
  final block = File(
    '${Directory.current.parent.path}/rules/storage/paths/home_care.rules',
  ).readAsStringSync();
  final storageRules = File(
    '${Directory.current.parent.path}/storage.rules',
  ).readAsStringSync();

  test('the home-care block is where this test thinks it is', () {
    expect(block, contains('// ---- home care photos'));
    expect(block, contains('match /households/{householdId}/homeCareJobs/'));
  });

  test('the size cap is the one the compressor refuses at', () {
    final cap = RegExp(r'(\d+) \* 1024 \* 1024').firstMatch(block);
    expect(int.parse(cap!.group(1)!) * 1024 * 1024, HomeCarePhoto.maxBytes);
  });

  test('a JPEG is the only thing kept, which is what the compressor makes', () {
    expect(block, contains("'${CompressedPhoto.contentType}'"));
    expect(
      RegExp(r"'image/\w+'").allMatches(block).map((m) => m.group(0)).toSet(),
      {"'image/jpeg'"},
    );
  });

  test('the path the store writes is the path the rules guard', () {
    expect(
      StorageJobPhotoStore.pathFor(
        householdId: 'h',
        jobId: 'j',
        photoId: 'before',
      ),
      'households/h/homeCareJobs/j/before',
    );
    expect(block, contains('isStampedWithTheCaller()'));
    expect(
      storageRules,
      contains('request.resource.metadata.${StorageJobPhotoStore.uploaderKey}'),
    );
  });
}
