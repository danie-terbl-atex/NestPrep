import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/data/kept_lunch_photo_places.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Where a box was pictured, kept on the phone (lunch-box ADR-0029), so a
/// box shown before opens without asking `lunchPhoto`.
void main() {
  late Directory root;
  late KeptLunchPhotoPlaces places;
  final date = CalendarDate.parse('2026-09-29');

  setUp(() {
    root = Directory.systemTemp.createTempSync('lunch_photo_places');
    places = KeptLunchPhotoPlaces(root: () async => root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<String?> pathOf({String signature = 'main:wrap:Wrap'}) =>
      places.pathOf(
        householdId: 'house',
        childId: 'lwazi',
        date: date,
        signature: signature,
      );

  test('a box never pictured has no place', () async {
    expect(await pathOf(), isNull);
  });

  test('a pictured box is found again by a new store', () async {
    await places.remember(
      householdId: 'house',
      childId: 'lwazi',
      date: date,
      signature: 'main:wrap:Wrap',
      path: 'lunchPhotos/abc.jpg',
    );

    places = KeptLunchPhotoPlaces(root: () async => root);
    expect(await pathOf(), 'lunchPhotos/abc.jpg');
  });

  test('a changed box asks again', () async {
    await places.remember(
      householdId: 'house',
      childId: 'lwazi',
      date: date,
      signature: 'main:wrap:Wrap',
      path: 'lunchPhotos/abc.jpg',
    );

    expect(await pathOf(signature: 'main:wrap:Cheese wrap'), isNull);
  });

  test('a damaged file is no place', () async {
    await places.remember(
      householdId: 'house',
      childId: 'lwazi',
      date: date,
      signature: 'main:wrap:Wrap',
      path: 'lunchPhotos/abc.jpg',
    );
    File('${root.path}/lunch_photo_places/house_lwazi_2026-09-29.json')
        .writeAsStringSync('{not json');

    expect(await pathOf(), isNull);
  });
}
