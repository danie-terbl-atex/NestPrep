import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/list_scan/data/list_photo_picker.dart';
import 'package:nestprep/features/list_scan/state/list_scan_controller.dart';
import 'package:nestprep/features/list_scan/ui/list_scan_screen.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/recipes/data/recipe_groceries.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../test/support/fake_grocery_repository.dart';
import '../test/support/fake_list_scan.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Snap a shopping list's pictures (list-scan ADR-0001), through the shared
/// shutter: the way in, reading, the review, changing a line, and done.
/// `flutter test tool/list_scan_design_review_test.dart --update-goldens`
/// retakes them.
void main() {
  setUpAll(loadEveryFont);

  Future<void> capture(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required Future<void> Function(ListScanController controller) emit,
    double textScale = 1,
    FakeListScanReader? reader,
    Future<void> Function()? act,
  }) async {
    final groceries = FakeGroceryRepository();
    addTearDown(groceries.close);
    final lines = reader ?? FakeListScanReader();
    addTearDown(lines.complete);
    final controller = ListScanController(
      listScanReader: lines,
      listPhotoPicker: FakeListPhotoPicker(),
      groceries: RecipeGroceries(
        groceryRepository: groceries,
        matched: ShopWeekGroceries(
          groceryRepository: groceries,
          householdId: Fixtures.householdId,
          memberId: Fixtures.samMemberId,
        ),
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      householdId: Fixtures.householdId,
    );
    addTearDown(controller.dispose);
    await captureScreen(
      tester,
      name,
      brightness: brightness,
      textScale: textScale,
      screen: heldStill(const ListScanScreen(memberId: Fixtures.samMemberId)),
      providers: [
        ChangeNotifierProvider<ListScanController>.value(value: controller),
      ],
      emit: () => emit(controller),
      act: act,
    );
  }

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('list scan, the way in — $theme', (tester) async {
      await capture(
        tester,
        'list-scan-$theme',
        brightness: brightness,
        emit: (_) async {},
      );
    });

    testWidgets('list scan, reading — $theme', (tester) async {
      await capture(
        tester,
        'list-scan-reading-$theme',
        brightness: brightness,
        reader: FakeListScanReader()..gate = Completer<void>(),
        emit: (controller) async =>
            unawaited(controller.pick(ListPhotoSource.camera)),
      );
    });

    testWidgets('list scan, the review — $theme', (tester) async {
      await capture(
        tester,
        'list-scan-review-$theme',
        brightness: brightness,
        emit: (controller) async {
          await controller.pick(ListPhotoSource.camera);
          controller.toggle(1);
        },
      );
    });

    testWidgets('list scan, changing a line — $theme', (tester) async {
      await capture(
        tester,
        'list-scan-change-$theme',
        brightness: brightness,
        emit: (controller) => controller.pick(ListPhotoSource.camera),
        act: () async {
          await tester.tap(
            find.bySemanticsLabel(ListScanCopy.change('Full cream milk')),
          );
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('list scan, added — $theme', (tester) async {
      await capture(
        tester,
        'list-scan-added-$theme',
        brightness: brightness,
        emit: (controller) async {
          await controller.pick(ListPhotoSource.camera);
          controller.shopped(3);
        },
      );
    });
  }

  testWidgets('list scan, the review — dark at 200% text', (tester) async {
    await capture(
      tester,
      'list-scan-review-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
      emit: (controller) => controller.pick(ListPhotoSource.camera),
    );
  });
}
