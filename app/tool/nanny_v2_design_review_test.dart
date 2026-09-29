import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/photo_update.dart';
import 'package:nestprep/features/nanny_hub/state/bookings_controller.dart';
import 'package:nestprep/features/nanny_hub/state/house_codes_controller.dart';
import 'package:nestprep/features/nanny_hub/state/nanny_hub_controller.dart';
import 'package:nestprep/features/nanny_hub/state/offline_keeper.dart';
import 'package:nestprep/features/nanny_hub/state/photo_feed_controller.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/features/nanny_hub/state/shift_pass_controller.dart';
import 'package:nestprep/features/nanny_hub/ui/bookings_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/carer_scope.dart';
import 'package:nestprep/features/nanny_hub/ui/emergency_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/house_codes_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/off_shift_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/photo_feed_screen.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/household_fixtures.dart';
import '../test/support/nanny_access_fixtures.dart';
import '../test/support/nanny_fixtures.dart';
import '../test/support/pump_nanny_hub.dart';
import '../test/support/test_flags.dart';
import 'review_press.dart';

/// The nanny hub's V2 screens in the design-review press (nanny-hub ADR-0004,
/// ADR-0006, ADR-0007): the parents' live photo feed, booked shifts, the
/// house codes open and shut, what a carer kept to their shifts sees between
/// them, and the emergency sheet with no signal. Pictures to look at rather
/// than assertions: regenerate with
///
///     flutter test tool/nanny_v2_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final now = DateTime.now().toUtc();

  HouseholdView shiftOnly(HouseholdView view) => HouseholdView(
    household: view.household.copyWith(
      shiftOnly: const {NannyFixtures.nomsaMemberId: true},
    ),
    members: view.members,
    viewerUid: view.viewerUid,
  );

  Future<void> press(
    WidgetTester tester,
    String name, {
    required Widget screen,
    required HouseholdView view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool isOnShift = true,
    bool noSignal = false,
  }) async {
    final fakes = NannyFakes();
    fakes.photos.objects['photo-fort-01'] = _aPicture(
      img.ColorRgb8(46, 94, 78),
    );
    fakes.photos.objects['photo-bath-01'] = _aPicture(
      img.ColorRgb8(47, 128, 140),
    );
    fakes.codes.codes = const [AccessFixtures.alarm, AccessFixtures.gate];
    if (noSignal) fakes.warmer.failWith = const UnavailableFailure();
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
    final isFamily = view.permissions.isFamily;
    final pass = ShiftPassController(
      bookingRepository: fakes.bookings,
      householdId: Fixtures.householdId,
      memberId: view.viewerMember?.id,
      isFamily: isFamily,
      now: DateTime.now,
    );
    final feed = PhotoFeedController(
      photoUpdateRepository: fakes.photoUpdates,
      shiftRepository: fakes.shifts,
      photos: photos,
      householdId: Fixtures.householdId,
      shiftId: 'shift-1',
      memberId: view.viewerMember?.id ?? '',
      isFamily: isFamily,
    );
    final bookings = BookingsController(
      bookingRepository: fakes.bookings,
      shiftDirectory: fakes.directory,
      householdId: Fixtures.householdId,
      viewerMemberId: view.viewerMember?.id,
      isFamily: isFamily,
      now: DateTime.now,
    );
    final codes = HouseCodesController(
      houseCodeRepository: fakes.codes,
      pass: pass,
      householdId: Fixtures.householdId,
      memberId: view.viewerMember?.id,
      isFamily: isFamily,
    );
    final keeper = OfflineKeeper(
      cacheWarmer: fakes.warmer,
      shelf: fakes.shelf,
      photoStore: fakes.photos,
      documentDirectory: fakes.documents,
      householdId: Fixtures.householdId,
      request: CarerScope.warmRequestFor(view),
      now: DateTime.now,
    );
    fakes.shelf.stamps[Fixtures.householdId] = now.subtract(
      const Duration(hours: 3),
    );
    addTearDown(() async {
      codes.dispose();
      bookings.dispose();
      feed.dispose();
      keeper.dispose();
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
        ChangeNotifierProvider<ShiftPassController>.value(value: pass),
        ChangeNotifierProvider<PhotoFeedController>.value(value: feed),
        ChangeNotifierProvider<BookingsController>.value(value: bookings),
        ChangeNotifierProvider<HouseCodesController>.value(value: codes),
        ChangeNotifierProvider<OfflineKeeper>.value(value: keeper),
        ChangeNotifierProvider(
          create: (_) => testFlagsController(TestFlags.on),
        ),
      ],
      emit: () async {
        fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
        fakes.shifts.shift.add(NannyFixtures.openShift);
        fakes.photoUpdates.updates.add([
          PhotoUpdate(
            id: 'u2',
            photoId: 'photo-bath-01',
            caption: 'Bath done, pyjamas on',
            childIds: const [Fixtures.kidMemberId],
            byMemberId: NannyFixtures.nomsaMemberId,
            createdAt: now.subtract(const Duration(minutes: 4)),
          ),
          PhotoUpdate(
            id: 'u1',
            photoId: 'photo-fort-01',
            caption: 'A fort in the lounge',
            childIds: const [Fixtures.kidMemberId],
            byMemberId: NannyFixtures.nomsaMemberId,
            createdAt: now.subtract(const Duration(minutes: 52)),
          ),
        ]);
        fakes.bookings.bookings.add([
          AccessFixtures.booking(
            now: now,
            from: isOnShift
                ? const Duration(hours: -1)
                : const Duration(hours: 20),
            note: 'School pick-up at 14:30, then home',
          ),
          AccessFixtures.booking(
            id: 'b2',
            now: now,
            from: const Duration(days: 2, hours: 3),
            length: const Duration(hours: 5),
          ),
        ]);
        await tester.pump();
        if (noSignal) await keeper.saveNow();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
      },
    );
    // The window's next edge is a timer; the picture is taken, so the tree
    // goes and the timer with it before the test's pending-timer check.
    await tester.pumpWidget(const SizedBox.shrink());
    pass.dispose();
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    testWidgets('the parents’ photo feed — $suffix', (tester) async {
      await press(
        tester,
        'nanny-photo-feed-$suffix',
        screen: const PhotoFeedScreen(),
        view: NannyFixtures.parentView(),
        brightness: brightness,
      );
    });

    testWidgets('booked shifts — $suffix', (tester) async {
      await press(
        tester,
        'nanny-bookings-$suffix',
        screen: const BookingsScreen(),
        view: shiftOnly(NannyFixtures.parentView()),
        brightness: brightness,
      );
    });

    testWidgets('house codes on shift — $suffix', (tester) async {
      await press(
        tester,
        'nanny-codes-$suffix',
        screen: const HouseCodesScreen(),
        view: NannyFixtures.carerView(),
        brightness: brightness,
      );
    });

    testWidgets('between shifts — $suffix', (tester) async {
      await press(
        tester,
        'nanny-off-shift-$suffix',
        screen: Builder(
          builder: (context) => OffShiftScreen(
            upcoming: context.watch<ShiftPassController>().stillToCome,
            onCheckAgain: () {},
          ),
        ),
        view: shiftOnly(NannyFixtures.carerView()),
        brightness: brightness,
        isOnShift: false,
      );
    });
  }

  testWidgets('house codes shut between shifts — light', (tester) async {
    await press(
      tester,
      'nanny-codes-closed-light',
      screen: const HouseCodesScreen(),
      view: NannyFixtures.carerView(),
      isOnShift: false,
    );
  });

  testWidgets('the emergency sheet with no signal — light', (tester) async {
    await press(
      tester,
      'nanny-emergency-no-signal-light',
      screen: const EmergencyScreen(),
      view: NannyFixtures.carerView(),
      noSignal: true,
    );
  });

  testWidgets('booked shifts at 200% text — dark', (tester) async {
    await press(
      tester,
      'nanny-bookings-large-text-dark',
      screen: const BookingsScreen(),
      view: shiftOnly(NannyFixtures.parentView()),
      brightness: Brightness.dark,
      textScale: 2,
    );
  });
}

/// A small picture with a sky and a hill, so a photo slot reads as a photo.
Uint8List _aPicture(img.Color ground) {
  final image = img.Image(width: 160, height: 120)
    ..clear(img.ColorRgb8(236, 222, 196));
  img.fillCircle(image, x: 80, y: 150, radius: 90, color: ground);
  img.fillCircle(
    image,
    x: 124,
    y: 30,
    radius: 14,
    color: img.ColorRgb8(233, 160, 70),
  );
  return img.encodeJpg(image);
}
