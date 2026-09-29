import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/data/document_directory.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/data/booking_repository.dart';
import 'package:nestprep/features/nanny_hub/data/cache_warmer.dart';
import 'package:nestprep/features/nanny_hub/data/offline_shelf.dart';
import 'package:nestprep/features/nanny_hub/data/photo_store.dart';
import 'package:nestprep/features/nanny_hub/ui/carer_scope.dart';
import 'package:nestprep/features/nanny_hub/ui/hub_clock.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_nanny_access.dart';
import '../../../support/fake_nanny_hub.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/nanny_access_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';
import '../../../support/pump_screen.dart';
import '../../../support/test_flags.dart';

/// Shift-only access around the whole household (nanny-hub ADR-0006): a carer
/// kept to their booked shifts sees the household only inside one, and meets
/// a kind screen outside it; the edges of the window move the offline copy
/// (nanny-hub ADR-0007).
void main() {
  const household = 'the household';

  late FakeBookingRepository bookings;
  late FakeCacheWarmer warmer;
  late FakeOfflineShelf shelf;

  setUp(() {
    bookings = FakeBookingRepository();
    warmer = FakeCacheWarmer();
    shelf = FakeOfflineShelf();
  });
  tearDown(() => bookings.close());

  // Made after the pump, which is what loads the timezone data.
  HouseholdClock clock() => HouseholdClock('Africa/Johannesburg');

  Future<void> open(WidgetTester tester, HouseholdView view) async {
    await pumpScreen(
      tester,
      const CarerScope(child: Text(household)),
      view: view,
      providers: [
        ChangeNotifierProvider(
          create: (_) => testFlagsController(TestFlags.on),
        ),
        Provider<BookingRepository>.value(value: bookings),
        Provider<CacheWarmer>.value(value: warmer),
        Provider<OfflineShelf>.value(value: shelf),
        Provider<PhotoStore>.value(value: FakePhotoStore()),
        Provider<DocumentDirectory>.value(value: FakeDocumentDirectory()),
      ],
    );
    await tester.pump();
  }

  testWidgets('a carer kept to their shifts, between them, sees when the next '
      'is and when the household opens — and not the household', (
    tester,
  ) async {
    final next = AccessFixtures.booking(
      now: DateTime.now(),
      from: const Duration(hours: 6),
    );
    await open(tester, AccessFixtures.shiftOnlyCarerView());
    bookings.bookings.add([next]);
    await tester.pumpAndSettle();

    expect(find.text(household), findsNothing);
    expect(find.text(NannyBookingCopy.offShiftTitle), findsOneWidget);
    expect(
      find.text(NannyBookingCopy.offShiftNext(clock().bookingOf(next))),
      findsOneWidget,
    );
    expect(
      find.text(NannyBookingCopy.opensAt(clock().timeOf(next.opensAt))),
      findsOneWidget,
    );
  });

  testWidgets('with nothing booked, it says the household opens for a booked '
      'shift', (tester) async {
    await open(tester, AccessFixtures.shiftOnlyCarerView());
    bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(find.text(household), findsNothing);
    expect(find.text(NannyBookingCopy.offShiftNone), findsOneWidget);
  });

  testWidgets('inside a booked shift the household is there', (tester) async {
    await open(tester, AccessFixtures.shiftOnlyCarerView());
    bookings.bookings.add([
      AccessFixtures.booking(
        now: DateTime.now(),
        from: const Duration(hours: -1),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text(household), findsOneWidget);
    expect(find.text(NannyBookingCopy.offShiftTitle), findsNothing);
  });

  testWidgets('before the bookings have answered, nothing of the household '
      'shows', (tester) async {
    await open(tester, AccessFixtures.shiftOnlyCarerView());
    expect(find.text(household), findsNothing);
    bookings.bookings.add([]);
    await tester.pumpAndSettle();
  });

  testWidgets('family is never kept to a booking', (tester) async {
    await open(tester, NannyFixtures.parentView());
    expect(find.text(household), findsOneWidget);
    expect(bookings.bookings.hasListener, isFalse);
  });

  testWidgets('a carer who is not kept to their shifts sees the household '
      'with nothing booked — and it is saved for offline as the app opens', (
    tester,
  ) async {
    await open(tester, NannyFixtures.carerView());
    bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(find.text(household), findsOneWidget);
    expect(warmer.requests, hasLength(1));
  });

  testWidgets('the window closing takes the offline copy off the phone', (
    tester,
  ) async {
    final booking = AccessFixtures.booking(
      now: DateTime.now(),
      from: const Duration(hours: -1),
    );
    await open(tester, AccessFixtures.shiftOnlyCarerView());
    bookings.bookings.add([booking]);
    await tester.pumpAndSettle();
    expect(shelf.cleared, isEmpty);

    // A parent cancels it: the window shuts now.
    bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(find.text(household), findsNothing);
    expect(shelf.cleared, [Fixtures.householdId]);
  });

  testWidgets('the window opening saves everything fresh for no signal', (
    tester,
  ) async {
    await open(tester, AccessFixtures.shiftOnlyCarerView());
    bookings.bookings.add([]);
    await tester.pumpAndSettle();
    expect(warmer.requests, isEmpty);

    bookings.bookings.add([
      AccessFixtures.booking(
        now: DateTime.now(),
        from: const Duration(minutes: -5),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text(household), findsOneWidget);
    expect(warmer.requests, hasLength(1));
  });

  testWidgets('"Check again" reads the bookings again', (tester) async {
    await open(tester, AccessFixtures.shiftOnlyCarerView());
    bookings.bookings.add([]);
    await tester.pumpAndSettle();
    bookings.askedForCarer = null;

    await tester.tap(find.text(NannyBookingCopy.checkAgain));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(bookings.askedForCarer, NannyFixtures.nomsaMemberId);
    bookings.bookings.add([
      AccessFixtures.booking(
        now: DateTime.now(),
        from: const Duration(hours: -1),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text(household), findsOneWidget);
  });

  testWidgets('a failed read says so and offers to try again', (tester) async {
    await open(tester, AccessFixtures.shiftOnlyCarerView());
    bookings.bookings.addError(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(find.text(household), findsNothing);
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('the off-shift screen holds at 360 wide, in dark, at 200% '
      'text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      const CarerScope(child: Text(household)),
      view: AccessFixtures.shiftOnlyCarerView(),
      brightness: Brightness.dark,
      textScale: 2,
      providers: [
        ChangeNotifierProvider(
          create: (_) => testFlagsController(TestFlags.on),
        ),
        Provider<BookingRepository>.value(value: bookings),
        Provider<CacheWarmer>.value(value: warmer),
        Provider<OfflineShelf>.value(value: shelf),
        Provider<PhotoStore>.value(value: FakePhotoStore()),
        Provider<DocumentDirectory>.value(value: FakeDocumentDirectory()),
      ],
    );
    await tester.pump();
    final now = DateTime.now();
    bookings.bookings.add([
      for (var day = 1; day <= 4; day++)
        AccessFixtures.booking(
          now: now,
          id: 'b$day',
          from: Duration(days: day),
          note: 'School pick-up at 14:30, then home',
        ),
    ]);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(NannyBookingCopy.checkAgain));
    expect(tester.takeException(), isNull);
  });

  group('the hub', () {
    late NannyFakes fakes;

    setUp(() => fakes = NannyFakes());
    tearDown(() => fakes.close());

    testWidgets('a carer kept to their shifts is told until when they can see '
        'the household', (tester) async {
      final booking = AccessFixtures.booking(
        now: DateTime.now(),
        from: const Duration(hours: -1),
      );
      await pumpNannyHub(
        tester,
        fakes,
        view: AccessFixtures.shiftOnlyCarerView(),
      );
      fakes.answerAFullHub();
      // The hub's home is what first asks for the window, so the bookings
      // answer once it is there.
      await tester.pumpAndSettle();
      fakes.bookings.bookings.add([booking]);
      await tester.pumpAndSettle();
      expect(
        find.text(NannyBookingCopy.openUntil(clock().timeOf(booking.closesAt))),
        findsOneWidget,
      );
    });

    testWidgets('a carer not kept to their shifts gets no such line', (
      tester,
    ) async {
      await pumpNannyHub(tester, fakes, view: NannyFixtures.carerView());
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      fakes.bookings.bookings.add([
        AccessFixtures.booking(
          now: DateTime.now(),
          from: const Duration(hours: -1),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.textContaining('You can see the household'), findsNothing);
    });

    testWidgets('booked shifts and house codes are places in the hub, reached '
        'from it', (tester) async {
      await pumpNannyHub(tester, fakes);
      fakes.answerAFullHub();
      fakes.bookings.bookings.add([]);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text(NannyBookingCopy.codes));
      expect(find.text(NannyBookingCopy.bookings), findsOneWidget);
      await tester.tap(find.text(NannyBookingCopy.codes));
      await tester.pumpAndSettle();
      expect(find.text(NannyBookingCopy.codesTitle), findsOneWidget);
    });

    testWidgets('switched off, neither place is offered', (tester) async {
      await pumpNannyHub(tester, fakes, flags: TestFlags.off);
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text(NannyCopy.checklists));
      expect(find.text(NannyBookingCopy.bookings), findsNothing);
      expect(find.text(NannyBookingCopy.codes), findsNothing);
    });
  });
}
