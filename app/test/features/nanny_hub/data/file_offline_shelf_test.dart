import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/data/file_offline_shelf.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The phone's own shelf for the hub's photos (nanny-hub ADR-0007), against
/// a real folder: what goes on comes back byte for byte, per household, and
/// nothing but a generated id ever becomes a path.
void main() {
  late Directory root;
  late FileOfflineShelf shelf;
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 7, 8, 9]);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nanny_shelf_test');
    shelf = FileOfflineShelf(root: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a kept photo reads back byte for byte', () async {
    await shelf.keepPhoto(householdId: 'h1', photoId: 'photo_A-1', jpeg: jpeg);
    expect(
      await shelf.hasPhoto(householdId: 'h1', photoId: 'photo_A-1'),
      isTrue,
    );
    expect(
      await shelf.readPhoto(householdId: 'h1', photoId: 'photo_A-1'),
      jpeg,
    );
  });

  test('a photo never kept is null, not an error', () async {
    expect(
      await shelf.readPhoto(householdId: 'h1', photoId: 'nope1234'),
      isNull,
    );
    expect(
      await shelf.hasPhoto(householdId: 'h1', photoId: 'nope1234'),
      isFalse,
    );
  });

  test('leaves no half-written photo behind', () async {
    await shelf.keepPhoto(householdId: 'h1', photoId: 'photo1', jpeg: jpeg);
    final names = [
      await for (final entity in root.list(recursive: true))
        entity.path.split('/').last,
    ];
    expect(names.where((name) => name.endsWith('.partial')), isEmpty);
  });

  test('remembers when it was saved, in UTC', () async {
    expect(await shelf.savedAt('h1'), isNull);
    final at = DateTime.utc(2026, 9, 29, 15, 4);
    await shelf.markSaved('h1', at);
    expect(await shelf.savedAt('h1'), at);
  });

  test('clearing one household leaves another alone', () async {
    await shelf.keepPhoto(householdId: 'h1', photoId: 'photo1', jpeg: jpeg);
    await shelf.keepPhoto(householdId: 'h2', photoId: 'photo1', jpeg: jpeg);
    await shelf.markSaved('h1', DateTime.utc(2026));
    await shelf.clear('h1');
    expect(await shelf.hasPhoto(householdId: 'h1', photoId: 'photo1'), isFalse);
    expect(await shelf.savedAt('h1'), isNull);
    expect(await shelf.hasPhoto(householdId: 'h2', photoId: 'photo1'), isTrue);
  });

  test('clearing a household with nothing kept is fine', () async {
    await shelf.clear('never');
  });

  test('nothing but a generated id becomes a path', () async {
    expect(
      () =>
          shelf.keepPhoto(householdId: 'h1', photoId: '../escape', jpeg: jpeg),
      throwsArgumentError,
    );
    expect(() => shelf.savedAt('../../etc'), throwsArgumentError);
  });

  test('a folder the phone will not write says it could not save', () async {
    final blocked = File('${root.path}/not_a_folder');
    await blocked.writeAsString('in the way');
    final stuck = FileOfflineShelf(root: () async => Directory(blocked.path));
    await expectLater(
      stuck.keepPhoto(householdId: 'h1', photoId: 'photo1', jpeg: jpeg),
      throwsA(
        isA<NannyHubFailure>().having(
          (failure) => failure.problem,
          'problem',
          NannyHubProblem.cannotSaveOffline,
        ),
      ),
    );
  });
}
