import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/handover_kind.dart';
import 'package:nestprep/features/nanny_hub/model/handover_mood.dart';
import 'package:nestprep/features/nanny_hub/state/nanny_hub_controller.dart';
import 'package:nestprep/features/nanny_hub/state/offline_keeper.dart';
import 'package:nestprep/features/nanny_hub/state/photo_feed_controller.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/features/nanny_hub/state/shift_controller.dart';
import 'package:nestprep/features/nanny_hub/state/shift_pass_controller.dart';
import 'package:nestprep/features/nanny_hub/ui/carer_scope.dart';
import 'package:nestprep/features/nanny_hub/ui/child_card_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/emergency_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/nanny_hub_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/shift_screen.dart';
import 'package:nestprep/features/nanny_hub/ui/shift_summary_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_family_profiles.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/nanny_fixtures.dart';
import '../test/support/pump_nanny_hub.dart';
import '../test/support/test_flags.dart';
import 'review_press.dart';

/// The nanny hub in the design-review press — the hub as a carer finds it,
/// shift mode, a child's card, the emergency sheet and a finished shift's
/// summary, in light and dark, and shift mode at 200% text. Pictures to look
/// at rather than assertions: regenerate with
///
///     flutter test tool/nanny_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  /// The hub's controllers over the fakes, filled in, for [view].
  Future<({NannyFakes fakes, NannyHubController hub, PhotoLibrary photos})>
  hubFor(HouseholdView view) async {
    final fakes = NannyFakes();
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
    addTearDown(() async {
      hub.dispose();
      photos.dispose();
      await fakes.close();
    });
    return (fakes: fakes, hub: hub, photos: photos);
  }

  Future<void> press(
    WidgetTester tester,
    String name, {
    required Widget screen,
    required HouseholdView view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool withShift = false,
  }) async {
    final (:fakes, :hub, :photos) = await hubFor(view);
    final shift = ShiftController(
      shiftRepository: fakes.shifts,
      shiftDirectory: fakes.directory,
      photos: photos,
      householdId: Fixtures.householdId,
      shiftId: 'shift-1',
      memberId: NannyFixtures.nomsaMemberId,
    );
    addTearDown(shift.dispose);
    // V2 (nanny-hub ADR-0004, ADR-0006, ADR-0007): the shift's photos, the
    // household's booked-shift window and the offline line, as the household
    // shell and the shift route provide them.
    final feed = PhotoFeedController(
      photoUpdateRepository: fakes.photoUpdates,
      shiftRepository: fakes.shifts,
      photos: photos,
      householdId: Fixtures.householdId,
      shiftId: 'shift-1',
      memberId: view.viewerMember?.id ?? '',
      isFamily: view.permissions.isFamily,
    );
    final pass = ShiftPassController(
      bookingRepository: fakes.bookings,
      householdId: Fixtures.householdId,
      memberId: view.viewerMember?.id,
      isFamily: true,
      now: DateTime.now,
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
    fakes.shelf.stamps[Fixtures.householdId] = DateTime.now().subtract(
      const Duration(minutes: 12),
    );
    await keeper.open();
    addTearDown(() {
      feed.dispose();
      pass.dispose();
      keeper.dispose();
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
        ChangeNotifierProvider<ShiftController>.value(value: shift),
        ChangeNotifierProvider<PhotoFeedController>.value(value: feed),
        ChangeNotifierProvider<ShiftPassController>.value(value: pass),
        ChangeNotifierProvider<OfflineKeeper>.value(value: keeper),
        ChangeNotifierProvider(
          create: (_) => testFlagsController(TestFlags.on),
        ),
      ],
      emit: () async {
        fakes.answerAFullHub(
          openShifts: withShift ? [NannyFixtures.openShift] : const [],
        );
        await tester.pump();
        fakes.family.emitHealth(
          const MemberHealth(
            id: Fixtures.kidMemberId,
            medications: {'m1': FamilyFixtures.inhaler},
          ),
        );
        fakes.shifts.shift.add(NannyFixtures.openShift);
        fakes.photoUpdates.updates.add(const []);
        fakes.shifts.entries.add([
          NannyFixtures.tea,
          NannyFixtures.tea.copyWith(
            id: 'e-mood',
            kind: HandoverKind.mood,
            note: null,
            mood: HandoverMood.happy,
            at: NannyFixtures.startedAt.add(const Duration(minutes: 90)),
          ),
          NannyFixtures.tea.copyWith(
            id: 'e-nap',
            kind: HandoverKind.nap,
            note: 'Slept 13:00 to 14:10, woke up happy',
            at: NannyFixtures.startedAt.add(const Duration(minutes: 20)),
          ),
        ]);
      },
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    testWidgets('nanny hub — $suffix', (tester) async {
      await press(
        tester,
        'nanny-hub-$suffix',
        screen: const NannyHubScreen(),
        view: NannyFixtures.carerView(),
        brightness: brightness,
      );
    });

    testWidgets('shift mode — $suffix', (tester) async {
      await press(
        tester,
        'nanny-shift-$suffix',
        screen: const ShiftScreen(),
        view: NannyFixtures.carerView(),
        brightness: brightness,
        withShift: true,
      );
    });

    testWidgets('a child’s card — $suffix', (tester) async {
      await press(
        tester,
        'nanny-child-card-$suffix',
        screen: const ChildCardScreen(childId: Fixtures.kidMemberId),
        view: NannyFixtures.carerView(),
        brightness: brightness,
      );
    });

    testWidgets('the emergency sheet — $suffix', (tester) async {
      await press(
        tester,
        'nanny-emergency-$suffix',
        screen: const EmergencyScreen(),
        view: NannyFixtures.carerView(),
        brightness: brightness,
      );
    });

    testWidgets('a handover — $suffix', (tester) async {
      await press(
        tester,
        'nanny-handover-$suffix',
        screen: const ShiftSummaryScreen(shiftId: 'shift-0'),
        view: NannyFixtures.parentView(),
        brightness: brightness,
      );
    });
  }

  testWidgets('shift mode — dark, 200% text', (tester) async {
    await press(
      tester,
      'nanny-shift-dark-200-percent-text',
      screen: const ShiftScreen(),
      view: NannyFixtures.carerView(),
      brightness: Brightness.dark,
      textScale: 2,
      withShift: true,
    );
  });
}
