import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/product_kind.dart';
import 'package:nestprep/features/home_care/model/room_kind.dart';
import 'package:nestprep/features/home_care/model/safety/precaution.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// The rooms and the product library (home-care ADR-0001, ADR-0002): a
/// parent keeps them, a helper reads them.
void main() {
  late HomeCareHarness harness;
  final rooms = HomeCareRoute.roomsPathFor(Fixtures.householdId);
  final products = HomeCareRoute.productsPathFor(Fixtures.householdId);

  setUp(() => harness = HomeCareHarness());
  tearDown(() => harness.close());

  Finder fieldLabelled(String label) => find.descendant(
    of: find.ancestor(
      of: find.text(label).first,
      matching: find.byType(NestTextField),
    ),
    matching: find.byType(EditableText),
  );

  group('rooms', () {
    testWidgets('a new household is one tap from the usual rooms', (
      tester,
    ) async {
      await harness.pump(tester, location: rooms);
      await harness.emit(tester, rooms: const []);
      await tester.tap(find.text(HomeCareLibraryCopy.addUsualRooms));
      await tester.pumpAndSettle();
      final (method, arguments) = harness.library.writes.single;
      expect(method, 'addRooms');
      expect(arguments['rooms'], HomeCareLibraryCopy.usualRooms);
    });

    testWidgets('each room says how many jobs are open in it', (tester) async {
      await harness.pump(tester, location: rooms);
      await harness.emit(tester);
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text(HomeCareLibraryCopy.openJobs(1)), findsOneWidget);
      expect(find.text(HomeCareLibraryCopy.openJobs(0)), findsOneWidget);
    });

    testWidgets('a parent adds a room with its name and its kind', (
      tester,
    ) async {
      await harness.pump(tester, location: rooms);
      await harness.emit(tester);
      await tester.tap(find.bySemanticsLabel(HomeCareLibraryCopy.addRoom));
      await tester.pumpAndSettle();
      await tester.enterText(
        fieldLabelled(HomeCareLibraryCopy.roomName),
        'Lily’s room',
      );
      await tester.tap(
        find.text(HomeCareLibraryCopy.roomKindName(RoomKind.kidsRoom)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppCopy.householdSave));
      await tester.pumpAndSettle();
      final (method, arguments) = harness.library.writes.single;
      expect(method, 'saveRoom');
      expect(arguments['name'], 'Lily’s room');
      expect(arguments['kind'], RoomKind.kidsRoom);
      expect(arguments['roomId'], isNull);
    });

    testWidgets('deleting a room asks first', (tester) async {
      await harness.pump(tester, location: rooms);
      await harness.emit(tester);
      await tester.tap(find.text('Bathroom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(HomeCareLibraryCopy.deleteRoom));
      await tester.pumpAndSettle();
      expect(find.text(HomeCareLibraryCopy.deleteRoomConfirm), findsOneWidget);
      await tester.tap(find.text(HomeCareLibraryCopy.deleteRoom).last);
      await tester.pumpAndSettle();
      expect(harness.library.writes.single.$2['roomId'], 'bathroom');
    });

    testWidgets('a helper reads the rooms and changes none', (tester) async {
      await harness.pump(
        tester,
        location: rooms,
        view: HomeCareFixtures.helperView(),
      );
      await harness.emit(tester, rooms: const []);
      expect(
        find.text(HomeCareLibraryCopy.roomsEmptyHelperBody),
        findsOneWidget,
      );
      expect(find.text(HomeCareLibraryCopy.addUsualRooms), findsNothing);
      expect(find.bySemanticsLabel(HomeCareLibraryCopy.addRoom), findsNothing);
    });
  });

  group('products', () {
    testWidgets('lists each with its kind, where it is kept, and a warning', (
      tester,
    ) async {
      await harness.pump(tester, location: products);
      await harness.emit(tester);
      expect(
        find.text(
          HomeCareLibraryCopy.kindAndPlace(
            HomeCareLibraryCopy.productKindName(ProductKind.bleach),
            'Under the sink',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(HomeCareSafetyCopy.needsCare)),
        findsNWidgets(2),
      );
    });

    testWidgets('a parent adds one, and sees what the helper will be told', (
      tester,
    ) async {
      HomeCareHarness.makeRoom(tester);
      await harness.pump(tester, location: products);
      await harness.emit(tester, products: const []);
      await tester.tap(find.text(HomeCareLibraryCopy.addProduct).last);
      await tester.pumpAndSettle();

      await tester.enterText(
        fieldLabelled(HomeCareLibraryCopy.productName),
        'Oven Pride',
      );
      await tester.tap(
        find.text(HomeCareLibraryCopy.productKindName(ProductKind.ovenCleaner)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          HomeCareSafetyCopy.precaution(Precaution.corrosive).toLowerCase(),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(HomeCareSafetyCopy.keepFromPetsChoice));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppCopy.householdSave));
      await tester.pumpAndSettle();

      final saved =
          harness.library.writes.single.$2['product']! as HomeCareProduct;
      expect(saved.name, 'Oven Pride');
      expect(saved.kind, ProductKind.ovenCleaner);
      expect(saved.keepFromPets, isTrue);
      expect(saved.createdBy, Fixtures.samMemberId);
    });

    testWidgets('a helper opens a product to read how to use it safely', (
      tester,
    ) async {
      HomeCareHarness.makeRoom(tester);
      await harness.pump(
        tester,
        location: products,
        view: HomeCareFixtures.helperView(),
      );
      await harness.emit(tester);
      expect(
        find.bySemanticsLabel(HomeCareLibraryCopy.addProduct),
        findsNothing,
      );
      await tester.tap(find.text('Jik'));
      await tester.pumpAndSettle();
      expect(
        find.text(HomeCareSafetyCopy.precaution(Precaution.onlyWithWater)),
        findsOneWidget,
      );
      expect(harness.library.writes, isEmpty);
    });

    testWidgets('where the advice comes from is one tap away', (tester) async {
      HomeCareHarness.makeRoom(tester);
      await harness.pump(
        tester,
        location: products,
        view: HomeCareFixtures.helperView(),
      );
      await harness.emit(tester);
      await tester.tap(find.text('Jik'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(HomeCareSafetyCopy.sourcesLink));
      await tester.pumpAndSettle();
      expect(find.text(HomeCareSafetyCopy.sourcesIntro), findsOneWidget);
    });
  });
}
