import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/data/photo_picker.dart';
import 'package:nestprep/features/nanny_hub/model/photo_update.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

/// Photo updates (nanny-hub ADR-0004): a carer sends the parents a picture
/// from shift mode in two taps; the parents watch them arrive in the shift's
/// feed; and the whole capability hides when its switch is off.
void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  final jpeg = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 40, height: 30)),
  );

  PhotoUpdate update(String id, {String? caption, String? by}) => PhotoUpdate(
    id: id,
    photoId: 'photo-$id',
    caption: caption,
    childIds: const [Fixtures.kidMemberId],
    byMemberId: by ?? NannyFixtures.nomsaMemberId,
    createdAt: DateTime.utc(2026, 9, 29, 12, 32),
  );

  /// A feed pushed over another screen opens its own reads, which the
  /// broadcast fakes answer only from now on.
  Future<void> answerTheFeed(
    WidgetTester tester, {
    Shift? shift,
    List<PhotoUpdate> updates = const [],
  }) async {
    await tester.pump();
    await tester.pump();
    fakes.shifts.shift.add(shift ?? NannyFixtures.openShift);
    fakes.photoUpdates.updates.add(updates);
    await tester.pumpAndSettle();
  }

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> openShiftMode(
    WidgetTester tester, {
    FeatureFlags flags = TestFlags.on,
    List<PhotoUpdate> sent = const [],
  }) async {
    tall(tester);
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.shiftPathFor(Fixtures.householdId, 'shift-1'),
      view: NannyFixtures.carerView(),
      flags: flags,
    );
    fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
    fakes.shifts.shift.add(NannyFixtures.openShift);
    fakes.shifts.entries.add([NannyFixtures.tea]);
    fakes.photoUpdates.updates.add(sent);
    await tester.pumpAndSettle();
  }

  Future<void> openFeed(
    WidgetTester tester, {
    HouseholdView? view,
    Shift? shift,
    List<PhotoUpdate> updates = const [],
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.photosPathFor(Fixtures.householdId, 'shift-1'),
      view: view ?? NannyFixtures.parentView(),
      brightness: brightness,
      textScale: textScale,
    );
    fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
    fakes.shifts.shift.add(shift ?? NannyFixtures.openShift);
    fakes.photoUpdates.updates.add(updates);
    await tester.pumpAndSettle();
  }

  group('in shift mode', () {
    testWidgets('a carer sends a photo with a caption in two taps and a word', (
      tester,
    ) async {
      fakes.picker.next = jpeg;
      await openShiftMode(tester);
      await tester.tap(find.text(NannyPhotoCopy.takeOne));
      await tester.pumpAndSettle();
      expect(find.text(NannyPhotoCopy.sheetTitle), findsOneWidget);
      await tester.enterText(
        fieldLabelled(NannyPhotoCopy.caption),
        'Fort in the lounge',
      );
      await tester.tap(find.text(NannyPhotoCopy.send));
      // Compression runs in a background isolate, which only real time moves.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();

      expect(fakes.picker.asked, [PhotoSource.camera]);
      final sent = fakes.photoUpdates.sent.single;
      expect(sent.caption, 'Fort in the lounge');
      expect(sent.childIds, [Fixtures.kidMemberId]);
      expect(sent.byMemberId, NannyFixtures.nomsaMemberId);
      // Stored first, compressed to a JPEG, and the update points at it.
      expect(fakes.photos.objects[sent.photoId]!.sublist(0, 2), [0xFF, 0xD8]);
    });

    testWidgets('choosing from the library works the same way', (tester) async {
      fakes.picker.next = jpeg;
      await openShiftMode(tester);
      await tester.tap(find.text(NannyPhotoCopy.chooseOne));
      await tester.pumpAndSettle();
      expect(fakes.picker.asked, [PhotoSource.library]);
      expect(find.text(NannyPhotoCopy.send), findsOneWidget);
    });

    testWidgets('backing out of the sheet sends nothing', (tester) async {
      fakes.picker.next = jpeg;
      await openShiftMode(tester);
      await tester.tap(find.text(NannyPhotoCopy.takeOne));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(fakes.photoUpdates.sent, isEmpty);
    });

    testWidgets('a refused photo says why in the banner', (tester) async {
      fakes.picker.next = jpeg;
      fakes.photoUpdates.failWritesWith = const PermissionDeniedFailure();
      await openShiftMode(tester);
      await tester.tap(find.text(NannyPhotoCopy.takeOne));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyPhotoCopy.send));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
    });

    testWidgets('says how many have gone, and opens them', (tester) async {
      await openShiftMode(tester, sent: [update('u1'), update('u2')]);
      expect(find.text(NannyPhotoCopy.sentSoFar(2)), findsOneWidget);
      await tester.tap(find.text(NannyPhotoCopy.sentSoFar(2)));
      await answerTheFeed(tester);
      expect(find.text(NannyPhotoCopy.feedTitle), findsOneWidget);
    });

    testWidgets('switched off, shift mode offers no photo updates', (
      tester,
    ) async {
      await openShiftMode(tester, flags: TestFlags.off);
      expect(find.text(NannyPhotoCopy.sendTitle), findsNothing);
      // The rest of shift mode is untouched.
      expect(find.text(NannyShiftCopy.logSomething), findsOneWidget);
    });
  });

  group('the parents’ feed', () {
    testWidgets('holds its layout while it loads', (tester) async {
      await pumpNannyHub(
        tester,
        fakes,
        location: NannyHubRoute.photosPathFor(Fixtures.householdId, 'shift-1'),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(NannyPhotoCopy.feedTitle), findsOneWidget);
    });

    testWidgets('shows every photo newest first, with its words, who sent it '
        'and who is in it', (tester) async {
      tall(tester);
      await openFeed(
        tester,
        updates: [
          update('u2', caption: 'Bath time'),
          update('u1'),
        ],
      );
      expect(find.text(NannyPhotoCopy.live), findsOneWidget);
      expect(find.text('Bath time'), findsOneWidget);
      expect(
        find.text(NannyPhotoCopy.from('Nomsa Carer', '14:32')),
        findsNWidgets(2),
      );
      expect(find.text('Kid Parker'), findsWidgets);
      final captionY = tester.getTopLeft(find.text('Bath time')).dy;
      final secondByline = tester
          .getTopLeft(
            find.text(NannyPhotoCopy.from('Nomsa Carer', '14:32')).last,
          )
          .dy;
      expect(captionY, lessThan(secondByline));
    });

    testWidgets('a live shift with nothing yet says they will come', (
      tester,
    ) async {
      await openFeed(tester);
      expect(find.text(NannyPhotoCopy.liveEmptyTitle), findsOneWidget);
      expect(
        find.text(NannyPhotoCopy.liveEmptyBody('Nomsa Carer')),
        findsOneWidget,
      );
    });

    testWidgets('an ended shift with none says so, not "still coming"', (
      tester,
    ) async {
      await openFeed(
        tester,
        shift: NannyFixtures.openShift.copyWith(status: Shift.ended),
      );
      expect(find.text(NannyPhotoCopy.ended), findsOneWidget);
      expect(find.text(NannyPhotoCopy.endedEmptyTitle), findsOneWidget);
    });

    testWidgets('a shift that is gone is said, not blank', (tester) async {
      await pumpNannyHub(
        tester,
        fakes,
        location: NannyHubRoute.photosPathFor(Fixtures.householdId, 'gone'),
      );
      fakes.answerAFullHub();
      fakes.shifts.shift.add(null);
      fakes.photoUpdates.updates.add(const []);
      await tester.pumpAndSettle();
      expect(find.text(NannyPhotoCopy.goneTitle), findsOneWidget);
    });

    testWidgets('a failed read offers to try again', (tester) async {
      await pumpNannyHub(
        tester,
        fakes,
        location: NannyHubRoute.photosPathFor(Fixtures.householdId, 'shift-1'),
      );
      fakes.answerAFullHub();
      fakes.photoUpdates.updates.addError(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('family takes a photo back after asking', (tester) async {
      tall(tester);
      await openFeed(tester, updates: [update('u1', caption: 'Oops')]);
      await tester.tap(find.byTooltip(NannyPhotoCopy.remove));
      await tester.pumpAndSettle();
      expect(find.text(NannyPhotoCopy.removeConfirm), findsOneWidget);
      await tester.tap(find.text(NannyPhotoCopy.removeAction));
      await tester.pumpAndSettle();
      expect(fakes.photoUpdates.removed, ['u1']);
    });

    testWidgets('a carer cannot take back somebody else’s photo', (
      tester,
    ) async {
      await openFeed(
        tester,
        view: NannyFixtures.carerView(),
        updates: [update('u1', by: Fixtures.samMemberId)],
      );
      expect(find.byTooltip(NannyPhotoCopy.remove), findsNothing);
    });

    testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await openFeed(
        tester,
        updates: [update('u1', caption: 'A long caption about a fort')],
        brightness: Brightness.dark,
        textScale: 2,
      );
      await scrollTo(tester, find.text('A long caption about a fort'));
      expect(tester.takeException(), isNull);
    });
  });

  group('the way in', () {
    testWidgets('a parent sees a carer’s live shift on the hub and opens its '
        'photos', (tester) async {
      tall(tester);
      await pumpNannyHub(tester, fakes);
      fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
      fakes.shifts.shift.add(NannyFixtures.openShift);
      fakes.photoUpdates.updates.add(const []);
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyPhotoCopy.liveFrom('Nomsa Carer')));
      await answerTheFeed(tester);
      expect(find.text(NannyPhotoCopy.liveEmptyTitle), findsOneWidget);
    });

    testWidgets('switched off, the hub offers no live photos', (tester) async {
      tall(tester);
      await pumpNannyHub(tester, fakes, flags: TestFlags.off);
      fakes.answerAFullHub(openShifts: [NannyFixtures.openShift]);
      await tester.pumpAndSettle();
      expect(find.text(NannyPhotoCopy.liveFrom('Nomsa Carer')), findsNothing);
    });

    testWidgets('a finished shift’s summary opens its photos', (tester) async {
      await pumpNannyHub(
        tester,
        fakes,
        location: NannyHubRoute.summaryPathFor(Fixtures.householdId, 'shift-0'),
      );
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(NannyPhotoCopy.shiftPhotos));
      await answerTheFeed(
        tester,
        shift: NannyFixtures.openShift.copyWith(status: Shift.ended),
      );
      expect(find.text(NannyPhotoCopy.endedEmptyTitle), findsOneWidget);
    });
  });
}
