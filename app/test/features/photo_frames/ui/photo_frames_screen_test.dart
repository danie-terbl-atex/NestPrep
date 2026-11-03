import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_area_preference.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_directory.dart';
import 'package:nestprep/features/photo_frames/model/frame_groceries.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/frame_screensaver.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';
import 'package:nestprep/features/photo_frames/state/frame_photos_controller.dart';
import 'package:nestprep/features/photo_frames/state/photo_frames_controller.dart';
import 'package:nestprep/features/photo_frames/ui/frame_scanner.dart';
import 'package:nestprep/features/photo_frames/ui/photo_frames_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_photo_frames.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  late FakePhotoFrameRepository repository;
  late PhotoFramesController controller;
  late FakeFramePhotoStore album;
  late FramePhotosController photos;
  late FakeCheckersAreaPreference areas;

  void build({List<Member>? members}) {
    controller = PhotoFramesController(
      photoFrameRepository: repository,
      householdId: Fixtures.householdId,
      members: members ?? [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
  }

  setUp(() {
    repository = FakePhotoFrameRepository();
    album = FakeFramePhotoStore(FramePhotoFixtures.album(3));
    build();
    photos = FramePhotoFixtures.controller(store: album);
    areas = FakeCheckersAreaPreference();
  });

  tearDown(() async {
    controller.dispose();
    photos.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    List<SingleChildWidget> extra = const [],
  }) => pumpScreen(
    tester,
    const PhotoFramesScreen(),
    providers: [
      ChangeNotifierProvider<PhotoFramesController>.value(value: controller),
      ChangeNotifierProvider<FramePhotosController>.value(value: photos),
      Provider<PhotoFrameDirectory>.value(value: FakePhotoFrameDirectory()),
      Provider<FrameScanner>.value(value: FakeFrameScanner()),
      Provider<CheckersAreaPreference>.value(value: areas),
      ...extra,
    ],
    brightness: brightness,
    textScale: scale,
  );

  Future<void> emit(WidgetTester tester, List<PhotoFrame> frames) async {
    repository.emit(frames);
    await tester.pumpAndSettle();
  }

  Future<void> openFrame(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.editTitle), findsOneWidget);
  }

  Finder inSheet(Finder finder) =>
      find.descendant(of: find.byType(BottomSheet), matching: finder);

  group('the four states', () {
    testWidgets('holds the layout while it loads', (tester) async {
      await pump(tester);
      await tester.pump();
      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
      expect(find.text(PhotoFrameCopy.title), findsOneWidget);
    });

    testWidgets('no frames invites linking one', (tester) async {
      await pump(tester);
      await emit(tester, const []);

      expect(find.text(PhotoFrameCopy.emptyTitle), findsOneWidget);
      await tester.tap(find.text(PhotoFrameCopy.link));
      await tester.pumpAndSettle();
      expect(find.text(PhotoFrameCopy.scanBody), findsOneWidget);
    });

    testWidgets('an unreadable list offers a retry', (tester) async {
      await pump(tester);
      repository.failWith(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('each frame, what it shows and when it was last seen', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester, [
        FrameFixtures.frame(
          panels: const FramePanels(
            todos: false,
            helperMemberId: Fixtures.thandiMemberId,
          ),
          lastSeenAt: FrameFixtures.now.subtract(const Duration(minutes: 5)),
        ),
      ]);

      expect(find.text('Kitchen frame'), findsOneWidget);
      expect(
        find.text(
          'Calendar · Meals · '
          '${PhotoFrameCopy.helperDay(Fixtures.thandi.displayName)}',
        ),
        findsOneWidget,
      );
      expect(find.text('Seen 5 minutes ago'), findsOneWidget);
      expect(find.byIcon(LucideIcons.clockAlert), findsNothing);
    });
  });

  group('last seen', () {
    testWidgets('a frame quiet for over an hour is flagged', (tester) async {
      await pump(tester);
      await emit(tester, [
        FrameFixtures.frame(
          lastSeenAt: FrameFixtures.now.subtract(const Duration(hours: 3)),
        ),
      ]);

      expect(find.textContaining('Last seen'), findsOneWidget);
      expect(find.byIcon(LucideIcons.clockAlert), findsOneWidget);
    });

    testWidgets('one just linked is waited for, not flagged', (tester) async {
      await pump(tester);
      await emit(tester, [
        FrameFixtures.frame(
          linkedAt: FrameFixtures.now.subtract(const Duration(minutes: 1)),
        ),
      ]);

      expect(find.text(PhotoFrameCopy.waitingToHear), findsOneWidget);
    });

    testWidgets('one never heard from since linking is flagged', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);

      expect(find.text(PhotoFrameCopy.notHeardSinceLinked), findsOneWidget);
      expect(find.byIcon(LucideIcons.clockAlert), findsOneWidget);
    });
  });

  group('one frame', () {
    testWidgets('renames it and changes what it shows', (tester) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await tester.enterText(inSheet(find.byType(TextField)), 'Hall frame');
      await tester.tap(inSheet(find.text(PhotoFrameCopy.meals)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(repository.updated.single.name, 'Hall frame');
      expect(repository.updated.single.panels.meals, isFalse);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('switches lunch boxes on', (tester) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await tester.tap(inSheet(find.text(PhotoFrameCopy.lunch)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(repository.updated.single.panels.lunch, isTrue);
    });

    testWidgets('lets an older frame add events', (tester) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await tester.tap(inSheet(find.text(PhotoFrameCopy.addEvents)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(repository.updated.single.panels.addEvents, isTrue);
    });

    testWidgets('lets an older frame open pages shared from phones', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.share)));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text(PhotoFrameCopy.share)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(repository.updated.single.panels.share, isTrue);
    });

    testWidgets('picks whose day it shows', (tester) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      expect(find.text(PhotoFrameCopy.chooseHelper), findsNothing);
      await tester.ensureVisible(
        inSheet(find.text(PhotoFrameCopy.helperTitle)),
      );
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text(PhotoFrameCopy.helperTitle)));
      await tester.pumpAndSettle();
      expect(find.text(PhotoFrameCopy.chooseHelper), findsOneWidget);
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(
        repository.updated.single.panels.helperMemberId,
        Fixtures.thandiMemberId,
      );
    });

    testWidgets('a household with no helper is not offered a helper’s day', (
      tester,
    ) async {
      controller.dispose();
      build(members: [Fixtures.sam, Fixtures.kid]);
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      expect(find.text(PhotoFrameCopy.helperTitle), findsNothing);
      expect(find.text(PhotoFrameCopy.calendar), findsOneWidget);
    });

    testWidgets('a name nobody can read is not saved', (tester) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await tester.enterText(inSheet(find.byType(TextField)), '   ');
      await tester.pumpAndSettle();
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(repository.updated, isEmpty);
    });

    testWidgets('a refused save is said in the sheet, once', (tester) async {
      repository.failWrites = const PermissionDeniedFailure();
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('unlinks it, after asking', (tester) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.unlink)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.unlink)));
      await tester.pumpAndSettle();
      expect(find.text(PhotoFrameCopy.unlinkConfirm), findsOneWidget);
      await tester.tap(
        find.widgetWithText(NestButton, PhotoFrameCopy.unlink).last,
      );
      await tester.pumpAndSettle();

      expect(repository.unlinked, ['frame-kitchen']);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('and keeps it when told to', (tester) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.unlink)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.unlink)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PhotoFrameCopy.keep));
      await tester.pumpAndSettle();

      expect(repository.unlinked, isEmpty);
      expect(find.text(PhotoFrameCopy.editTitle), findsOneWidget);
    });
  });

  group('the screensaver', () {
    testWidgets('the album is a row with its count', (tester) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);

      await tester.scrollUntilVisible(
        find.text(PhotoFrameCopy.photosTitle),
        200,
      );
      expect(find.text(PhotoFrameCopy.photoCount(3)), findsOneWidget);
      await tester.tap(find.text(PhotoFrameCopy.photosTitle));
      await tester.pumpAndSettle();
      expect(find.byType(Placeholder), findsOneWidget);
    });

    testWidgets('an empty album says so on its row', (tester) async {
      album.photos.clear();
      photos.dispose();
      photos = FramePhotoFixtures.controller(store: album);
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);

      await tester.scrollUntilVisible(
        find.text(PhotoFrameCopy.albumEntryEmpty),
        200,
      );
      expect(find.text(PhotoFrameCopy.albumEntryEmpty), findsOneWidget);
    });

    testWidgets('is off until chosen, then saves the wait and the pace', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      expect(find.text(PhotoFrameCopy.eachPhoto), findsNothing);
      await tester.ensureVisible(
        inSheet(find.text(PhotoFrameCopy.idleMinutes(5))),
      );
      await tester.tap(inSheet(find.text(PhotoFrameCopy.idleMinutes(5))));
      await tester.pumpAndSettle();
      expect(find.text(PhotoFrameCopy.eachPhoto), findsOneWidget);
      await tester.ensureVisible(
        inSheet(find.text(PhotoFrameCopy.seconds(60))),
      );
      await tester.tap(inSheet(find.text(PhotoFrameCopy.seconds(60))));
      await tester.pumpAndSettle();
      expect(find.text(PhotoFrameCopy.screensaverNeedsPhotos), findsNothing);
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(
        repository.updated.single.screensaver,
        const FrameScreensaver(idleMinutes: 5, secondsPerPhoto: 60),
      );
    });

    testWidgets('switching it off forgets the pace', (tester) async {
      await pump(tester);
      await emit(tester, [
        FrameFixtures.frame(
          screensaver: const FrameScreensaver(
            idleMinutes: 10,
            secondsPerPhoto: 30,
          ),
        ),
      ]);
      await openFrame(tester, 'Kitchen frame');

      expect(find.text(PhotoFrameCopy.eachPhoto), findsOneWidget);
      await tester.ensureVisible(
        inSheet(find.text(PhotoFrameCopy.screensaverOff)),
      );
      await tester.tap(inSheet(find.text(PhotoFrameCopy.screensaverOff)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();

      expect(repository.updated.single.screensaver, FrameScreensaver.off);
    });

    testWidgets('an empty album is pointed out once it is on', (tester) async {
      album.photos.clear();
      photos.dispose();
      photos = FramePhotoFixtures.controller(store: album);
      await pump(tester);
      await emit(tester, [
        FrameFixtures.frame(
          screensaver: const FrameScreensaver(idleMinutes: 2),
        ),
      ]);
      await openFrame(tester, 'Kitchen frame');

      expect(find.text(PhotoFrameCopy.screensaverNeedsPhotos), findsOneWidget);
    });
  });

  group('groceries from the frame', () {
    Finder groceriesSwitch() => find.descendant(
      of: find.widgetWithText(NestListRow, PhotoFrameCopy.groceries),
      matching: find.byType(Switch),
    );

    bool isOn(WidgetTester tester) =>
        tester.widget<Switch>(groceriesSwitch()).value;

    bool chipSelected<T>(WidgetTester tester, T key) =>
        tester.widget<NestChip>(find.byKey(ValueKey<T>(key))).isSelected;

    SingleChildWidget flags(Map<FeatureFlag, bool> stored) =>
        ChangeNotifierProvider<FeatureFlagsController>(
          create: (_) => testFlagsController(
            FeatureFlags(defaultOn: true, stored: stored),
          ),
        );

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.tap(inSheet(find.text(PhotoFrameCopy.save)));
      await tester.pumpAndSettle();
    }

    Future<void> switchOn(WidgetTester tester) async {
      await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.groceries)));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text(PhotoFrameCopy.groceries)));
      await tester.pumpAndSettle();
    }

    testWidgets('is not offered while every shop is switched off', (
      tester,
    ) async {
      await pump(
        tester,
        extra: [
          flags({
            FeatureFlag.addToCheckers: false,
            FeatureFlag.addToPnp: false,
          }),
        ],
      );
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      expect(find.text(PhotoFrameCopy.groceries), findsNothing);
      await save(tester);
      expect(repository.updated.single.groceries, isNull);
    });

    testWidgets('is off for a frame without it, with no shop or area shown', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      expect(isOn(tester), isFalse);
      expect(find.text(PhotoFrameCopy.groceriesShop), findsNothing);
      expect(find.text(PhotoFrameCopy.groceriesArea), findsNothing);
    });

    testWidgets(
      'switched on, it starts at the first shop on and this phone’s area',
      (tester) async {
        areas.chosen[Fixtures.householdId] = CheckersArea.durban;
        await pump(tester);
        await emit(tester, [FrameFixtures.frame()]);
        await openFrame(tester, 'Kitchen frame');

        await switchOn(tester);
        expect(isOn(tester), isTrue);
        expect(find.text(PhotoFrameCopy.groceriesShop), findsOneWidget);
        expect(find.text(PhotoFrameCopy.groceriesArea), findsOneWidget);
        expect(chipSelected(tester, ProductRetailer.checkers), isTrue);
        expect(chipSelected(tester, ProductRetailer.pickNPay), isFalse);
        expect(
          find.byKey(const ValueKey(ProductRetailer.woolworths)),
          findsNothing,
        );
        expect(chipSelected(tester, CheckersArea.durban), isTrue);
        await save(tester);

        expect(
          repository.updated.single.groceries,
          const FrameGroceries(
            shop: ProductRetailer.checkers,
            area: CheckersArea.durban,
          ),
        );
      },
    );

    testWidgets('with no area chosen on this phone it starts at the fallback', (
      tester,
    ) async {
      await pump(
        tester,
        extra: [
          flags({FeatureFlag.addToCheckers: false}),
        ],
      );
      await emit(tester, [FrameFixtures.frame()]);
      await openFrame(tester, 'Kitchen frame');

      await switchOn(tester);
      expect(
        find.byKey(const ValueKey(ProductRetailer.checkers)),
        findsNothing,
      );
      expect(chipSelected(tester, ProductRetailer.pickNPay), isTrue);
      expect(chipSelected(tester, CheckersArea.fallback), isTrue);
      await save(tester);

      expect(
        repository.updated.single.groceries,
        const FrameGroceries(
          shop: ProductRetailer.pickNPay,
          area: CheckersArea.fallback,
        ),
      );
    });

    testWidgets('a frame adding groceries loads its shop and area, and changes '
        'them', (tester) async {
      await pump(tester);
      await emit(tester, [
        FrameFixtures.frame(
          groceries: const FrameGroceries(
            shop: ProductRetailer.pickNPay,
            area: CheckersArea.pretoria,
          ),
        ),
      ]);
      await openFrame(tester, 'Kitchen frame');

      expect(isOn(tester), isTrue);
      expect(chipSelected(tester, ProductRetailer.pickNPay), isTrue);
      expect(chipSelected(tester, CheckersArea.pretoria), isTrue);
      await tester.ensureVisible(
        find.byKey(const ValueKey(ProductRetailer.checkers)),
      );
      await tester.tap(find.byKey(const ValueKey(ProductRetailer.checkers)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey(CheckersArea.eastLondon)),
      );
      await tester.tap(find.byKey(const ValueKey(CheckersArea.eastLondon)));
      await tester.pumpAndSettle();
      await save(tester);

      expect(
        repository.updated.single.groceries,
        const FrameGroceries(
          shop: ProductRetailer.checkers,
          area: CheckersArea.eastLondon,
        ),
      );
    });

    testWidgets('switching it off saves it off', (tester) async {
      await pump(tester);
      await emit(tester, [
        FrameFixtures.frame(
          groceries: const FrameGroceries(
            shop: ProductRetailer.checkers,
            area: CheckersArea.capeTown,
          ),
        ),
      ]);
      await openFrame(tester, 'Kitchen frame');

      await switchOn(tester);
      expect(isOn(tester), isFalse);
      expect(find.text(PhotoFrameCopy.groceriesShop), findsNothing);
      await save(tester);

      expect(repository.updated.single.groceries, isNull);
    });

    testWidgets('a frame adding at a shop since switched off keeps it', (
      tester,
    ) async {
      await pump(
        tester,
        extra: [
          flags({FeatureFlag.addToCheckers: false}),
        ],
      );
      await emit(tester, [
        FrameFixtures.frame(
          groceries: const FrameGroceries(
            shop: ProductRetailer.checkers,
            area: CheckersArea.johannesburg,
          ),
        ),
      ]);
      await openFrame(tester, 'Kitchen frame');

      expect(isOn(tester), isTrue);
      expect(chipSelected(tester, ProductRetailer.checkers), isTrue);
      expect(
        find.text(CheckersCopy.retailerName(ProductRetailer.pickNPay)),
        findsOneWidget,
      );
      await save(tester);

      expect(
        repository.updated.single.groceries,
        const FrameGroceries(
          shop: ProductRetailer.checkers,
          area: CheckersArea.johannesburg,
        ),
      );
    });
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await emit(tester, [
      FrameFixtures.frame(
        name: 'The big frame on the kitchen wall',
        panels: const FramePanels(helperMemberId: Fixtures.thandiMemberId),
        screensaver: const FrameScreensaver(idleMinutes: 15),
        groceries: const FrameGroceries(
          shop: ProductRetailer.pickNPay,
          area: CheckersArea.bloemfontein,
        ),
        lastSeenAt: FrameFixtures.now.subtract(const Duration(days: 2)),
      ),
    ]);
    expect(tester.takeException(), isNull);
    await openFrame(tester, 'The big frame on the kitchen wall');
    await tester.ensureVisible(
      inSheet(find.byKey(const ValueKey(CheckersArea.eastLondon))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(inSheet(find.text(PhotoFrameCopy.eachPhoto)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text(PhotoFrameCopy.photosTitle), 200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text(PhotoFrameCopy.link), 200);
    await tester.ensureVisible(find.text(PhotoFrameCopy.link));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.link));
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.scanBody), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(PhotoFrameCopy.typeInstead));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ABC234');
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.next));
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.linkAction), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
