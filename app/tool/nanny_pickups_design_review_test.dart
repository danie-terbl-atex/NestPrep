import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_person.dart';
import 'package:nestprep/features/nanny_hub/state/nanny_hub_controller.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/features/nanny_hub/state/pickup_controller.dart';
import 'package:nestprep/features/nanny_hub/ui/pickup_check_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/pickups_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/household_fixtures.dart';
import '../test/support/nanny_fixtures.dart';
import '../test/support/nanny_pickup_fixtures.dart';
import '../test/support/pump_nanny_hub.dart';
import 'review_press.dart';

/// Pickups in the design-review press (nanny-hub ADR-0005): the school run
/// as a parent edits it, and the door check as a carer holds it up — with
/// people listed, and with nobody. Pictures to look at rather than
/// assertions: regenerate with
///
///     flutter test tool/nanny_pickups_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  Future<void> press(
    WidgetTester tester,
    String name, {
    required Widget screen,
    required HouseholdView view,
    List<PickupPerson>? people,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final fakes = NannyFakes();
    fakes.photos.objects['photo-gogo-01'] = _aPortrait();
    final photos = PhotoLibrary(
      photoStore: fakes.photos,
      documentDirectory: fakes.documents,
      householdId: Fixtures.householdId,
      uploaderUid: view.viewerUid,
    );
    final hub = NannyHubController(
      nannyHubRepository: fakes.hub,
      shiftRepository: fakes.shifts,
      familyProfileRepository: fakes.family,
      householdId: Fixtures.householdId,
      household: view,
      photos: photos,
      photoPicker: fakes.picker,
      linkOpener: fakes.opener,
    );
    final pickups = PickupController(
      pickupRepository: fakes.pickups,
      photos: photos,
      householdId: Fixtures.householdId,
      memberId: view.viewerMember?.id ?? '',
      canEdit: view.permissions.isFamily,
      today: PickupFixtures.today,
    );
    addTearDown(() async {
      pickups.dispose();
      hub.dispose();
      photos.dispose();
      await fakes.close();
    });
    await captureScreen(
      tester,
      name,
      screen: screen,
      view: view,
      brightness: brightness,
      textScale: textScale,
      providers: [
        ChangeNotifierProvider<PhotoLibrary>.value(value: photos),
        ChangeNotifierProvider<NannyHubController>.value(value: hub),
        ChangeNotifierProvider<PickupController>.value(value: pickups),
      ],
      emit: () async {
        fakes.answerEverything(
          cards: [NannyFixtures.kidCard],
          contacts: [PickupFixtures.mom, NannyFixtures.gogo],
        );
        fakes.pickups.emitAll(
          peopleList: people ?? [PickupFixtures.gogo, PickupFixtures.thabo],
          runList: [
            PickupFixtures.todaysRun,
            PickupFixtures.todaysRun.copyWith(
              id: 'm-kid_x',
              weekday: PickupFixtures.today.addDays(1).weekday,
              personId: null,
              memberId: NannyFixtures.nomsaMemberId,
              place: null,
            ),
          ],
          changeList: [
            PickupFixtures.nomsaToday.copyWith(
              id: 'm-kid_later',
              date: PickupFixtures.today.addDays(3),
            ),
          ],
        );
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
      },
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    testWidgets('pickups — $suffix', (tester) async {
      await press(
        tester,
        'nanny-pickups-$suffix',
        screen: const PickupsScreen(),
        view: NannyFixtures.parentView(),
        brightness: brightness,
      );
    });

    testWidgets('door check — $suffix', (tester) async {
      await press(
        tester,
        'nanny-pickups-check-$suffix',
        screen: const PickupCheckScreen(childId: Fixtures.kidMemberId),
        view: NannyFixtures.carerView(),
        brightness: brightness,
      );
    });
  }

  testWidgets('door check, nobody listed — light', (tester) async {
    await press(
      tester,
      'nanny-pickups-check-nobody-light',
      screen: const PickupCheckScreen(childId: Fixtures.kidMemberId),
      view: NannyFixtures.carerView(),
      people: const [],
    );
  });

  testWidgets('pickups at 200% text — dark', (tester) async {
    await press(
      tester,
      'nanny-pickups-large-text-dark',
      screen: const PickupsScreen(),
      view: NannyFixtures.carerView(),
      brightness: Brightness.dark,
      textScale: 2,
    );
  });
}

/// A small picture with a face-like shape, so the photo slot reads as a
/// photo in the review rather than a blank tile.
Uint8List _aPortrait() {
  final image = img.Image(width: 120, height: 120)
    ..clear(img.ColorRgb8(200, 180, 150));
  img.fillCircle(
    image,
    x: 60,
    y: 48,
    radius: 26,
    color: img.ColorRgb8(120, 84, 60),
  );
  img.fillCircle(
    image,
    x: 60,
    y: 130,
    radius: 50,
    color: img.ColorRgb8(46, 94, 78),
  );
  return img.encodeJpg(image);
}
