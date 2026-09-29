import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/app/nanny_hub_routes.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/documents/data/document_directory.dart';
import 'package:nestprep/features/family_profiles/data/family_profile_repository.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/data/booking_repository.dart';
import 'package:nestprep/features/nanny_hub/data/cache_warmer.dart';
import 'package:nestprep/features/nanny_hub/data/house_code_repository.dart';
import 'package:nestprep/features/nanny_hub/data/nanny_hub_repository.dart';
import 'package:nestprep/features/nanny_hub/data/offline_shelf.dart';
import 'package:nestprep/features/nanny_hub/data/photo_picker.dart';
import 'package:nestprep/features/nanny_hub/data/photo_store.dart';
import 'package:nestprep/features/nanny_hub/data/photo_update_repository.dart';
import 'package:nestprep/features/nanny_hub/data/pickup_repository.dart';
import 'package:nestprep/features/nanny_hub/data/shift_directory.dart';
import 'package:nestprep/features/nanny_hub/data/shift_repository.dart';
import 'package:nestprep/features/nanny_hub/model/child_card.dart';
import 'package:nestprep/features/nanny_hub/model/emergency_contact.dart';
import 'package:nestprep/features/nanny_hub/model/guide_spot.dart';
import 'package:nestprep/features/nanny_hub/model/home_sheet.dart';
import 'package:nestprep/features/nanny_hub/model/house_rule.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/features/nanny_hub/model/shift_checklist.dart';
import 'package:nestprep/features/nanny_hub/model/shift_summary.dart';
import 'package:nestprep/features/nanny_hub/state/offline_keeper.dart';
import 'package:nestprep/features/nanny_hub/state/shift_pass_controller.dart';
import 'package:nestprep/features/nanny_hub/ui/carer_scope.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/links/external_link_opener.dart';
import 'package:provider/provider.dart';

import 'fake_documents.dart';
import 'fake_family_profiles.dart';
import 'fake_link_opener.dart';
import 'fake_nanny_access.dart';
import 'fake_nanny_hub.dart';
import 'fake_nanny_pickups.dart';
import 'household_fixtures.dart';
import 'nanny_fixtures.dart';
import 'pump_screen.dart';
import 'test_flags.dart';

/// Every fake behind the nanny hub, in one place a test can reach into.
final class NannyFakes {
  final hub = FakeNannyHubRepository();
  final shifts = FakeShiftRepository();
  final directory = FakeShiftDirectory();
  final photos = FakePhotoStore();
  final picker = FakePhotoPicker();
  final family = FakeFamilyProfileRepository();
  final documents = FakeDocumentDirectory();
  final opener = FakeLinkOpener();
  // pickups (nanny-hub ADR-0005)
  final pickups = FakePickupRepository();
  // photo updates, shift-only access and offline (nanny-hub ADR-0004,
  // ADR-0006, ADR-0007)
  final photoUpdates = FakePhotoUpdateRepository();
  final bookings = FakeBookingRepository();
  final codes = FakeHouseCodeRepository();
  final warmer = FakeCacheWarmer();
  final shelf = FakeOfflineShelf();

  /// Every read the hub makes answers: the authored records, the open shifts
  /// and the summaries, and the family profiles.
  void answerEverything({
    List<ChildCard> cards = const [],
    List<EmergencyContact> contacts = const [],
    HomeSheet sheet = HomeSheet.empty,
    List<GuideSpot> guide = const [],
    List<HouseRule> rules = const [],
    List<ShiftChecklist> checklists = const [],
    List<Shift> openShifts = const [],
    List<ShiftSummary> summaries = const [],
  }) {
    hub.emitAll(
      cardList: cards,
      contactList: contacts,
      home: sheet,
      spots: guide,
      ruleList: rules,
      lists: checklists,
    );
    shifts.openShifts.add(openShifts);
    shifts.summaries.add(summaries);
    family.emitProfiles([FamilyFixtures.kid]);
    family.emitSchools([FamilyFixtures.oakwood]);
  }

  /// A hub with something in every part of it.
  void answerAFullHub({List<Shift>? openShifts}) => answerEverything(
    cards: [NannyFixtures.kidCard],
    contacts: [NannyFixtures.gogo, NannyFixtures.doctor],
    sheet: NannyFixtures.home,
    guide: [NannyFixtures.nappies],
    rules: [NannyFixtures.screens],
    checklists: [NannyFixtures.bedtime],
    openShifts: openShifts ?? const [],
    summaries: [NannyFixtures.summary],
  );

  Future<void> close() async {
    await hub.close();
    await shifts.close();
    await family.close();
    await pickups.close();
    await photoUpdates.close();
    await bookings.close();
  }
}

/// The hub's real routes under a household, with the fakes behind them — so
/// a test drives the same shell, controllers and screens the app does, and a
/// tap that navigates lands on the real next screen (`FE-17`).
Future<void> pumpNannyHub(
  WidgetTester tester,
  NannyFakes fakes, {
  String? location,
  HouseholdView? view,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  FeatureFlags flags = TestFlags.on,
}) => pumpRouter(
  tester,
  router: GoRouter(
    initialLocation: location ?? NannyHubRoute.pathFor(Fixtures.householdId),
    routes: [
      nannyHubRoutes(),
      GoRoute(
        path: '/households/:householdId/household',
        builder: (context, state) => const Placeholder(),
      ),
    ],
  ),
  providers: [
    Provider<NannyHubRepository>.value(value: fakes.hub),
    Provider<ShiftRepository>.value(value: fakes.shifts),
    Provider<ShiftDirectory>.value(value: fakes.directory),
    Provider<PhotoStore>.value(value: fakes.photos),
    Provider<PhotoPicker>.value(value: fakes.picker),
    Provider<FamilyProfileRepository>.value(value: fakes.family),
    Provider<DocumentDirectory>.value(value: fakes.documents),
    Provider<ExternalLinkOpener>.value(value: fakes.opener),
    ChangeNotifierProvider(create: (_) => testFlagsController(flags)),
    // pickups (nanny-hub ADR-0005)
    Provider<PickupRepository>.value(value: fakes.pickups),
    // photo updates, shift-only access and offline (nanny-hub ADR-0004,
    // ADR-0006, ADR-0007), with the two the household shell's `CarerScope`
    // keeps for the whole household.
    Provider<PhotoUpdateRepository>.value(value: fakes.photoUpdates),
    Provider<BookingRepository>.value(value: fakes.bookings),
    Provider<HouseCodeRepository>.value(value: fakes.codes),
    Provider<CacheWarmer>.value(value: fakes.warmer),
    Provider<OfflineShelf>.value(value: fakes.shelf),
    ChangeNotifierProvider(
      create: (context) {
        final household = context.read<HouseholdView>();
        return ShiftPassController(
          bookingRepository: fakes.bookings,
          householdId: household.household.id,
          memberId: household.viewerMember?.id,
          isFamily: household.permissions.isFamily,
          now: DateTime.now,
        );
      },
    ),
    ChangeNotifierProvider(
      create: (context) => OfflineKeeper(
        cacheWarmer: fakes.warmer,
        shelf: fakes.shelf,
        photoStore: fakes.photos,
        documentDirectory: fakes.documents,
        householdId: Fixtures.householdId,
        request: CarerScope.warmRequestFor(context.read<HouseholdView>()),
        now: DateTime.now,
      ),
    ),
  ],
  view: view ?? NannyFixtures.parentView(),
  brightness: brightness,
  textScale: textScale,
);

/// The text field under a `NestTextField`'s label — the label sits above the
/// field rather than inside it.
Finder fieldLabelled(String label) => find.descendant(
  of: find.widgetWithText(NestTextField, label),
  matching: find.byType(EditableText),
);

/// Scrolls the screen's own list — not a selectable address's inner
/// scrollable — until [finder] is on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
