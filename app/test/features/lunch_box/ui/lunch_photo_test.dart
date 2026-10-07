import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/data/lunch_photo_source.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/art/lunch_box_art.dart';
import 'package:nestprep/features/lunch_box/ui/art/lunch_photo.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';

final class _RecordingPhotoSource implements LunchPhotoSource {
  _RecordingPhotoSource(this.photo);

  final Uint8List? photo;
  final asked = <String>[];

  @override
  Future<Uint8List?> photoFor({
    required String householdId,
    required String childId,
    required CalendarDate date,
    required String signature,
  }) async {
    asked.add('$childId ${date.iso} $signature');
    return photo;
  }
}

/// The photo frame (lunch-box ADR-0015): the drawn box always, and for a
/// premium household the photo of that exact box faded in over it.
void main() {
  final date = CalendarDate.parse('2026-09-29');
  final packed = LunchBox({LunchSlot.main: LunchPick.of(LunchFixtures.wrap)});
  final jpeg = File('assets/brand/welcome_lunch.jpg').readAsBytesSync();

  Future<_RecordingPhotoSource> pump(
    WidgetTester tester, {
    required bool isPremium,
    LunchBox? box,
  }) async {
    final harness = LunchHarness(isPremium: isPremium);
    addTearDown(harness.close);
    final source = _RecordingPhotoSource(jpeg);
    await pumpScreen(
      tester,
      SizedBox(
        width: 320,
        height: 240,
        child: LunchPhoto(
          box: box ?? packed,
          childId: LunchFixtures.lwaziId,
          date: date,
        ),
      ),
      providers: [
        ...harness.providers,
        Provider<LunchPhotoSource>.value(value: source),
      ],
    );
    await tester.pumpAndSettle();
    return source;
  }

  testWidgets('a premium household sees the photo of that box', (tester) async {
    final source = await pump(tester, isPremium: true);

    expect(source.asked, [
      '${LunchFixtures.lwaziId} 2026-09-29 main:${LunchFixtures.wrap.id}',
    ]);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(LunchBoxArt), findsOneWidget);
  });

  testWidgets('a free household keeps the drawn box and never asks', (
    tester,
  ) async {
    final source = await pump(tester, isPremium: false);

    expect(source.asked, isEmpty);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(LunchBoxArt), findsOneWidget);
  });

  testWidgets('an empty box is never sent for a photo', (tester) async {
    final source = await pump(tester, isPremium: true, box: LunchBox(const {}));

    expect(source.asked, isEmpty);
  });
}
