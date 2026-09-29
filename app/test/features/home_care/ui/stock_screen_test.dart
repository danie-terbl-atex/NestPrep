import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/features/home_care/model/stock_level.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// The stock tracker through the real routes (home-care ADR-0005): what is
/// running low first, four big levels per product, and a mark in the
/// viewer's own name — a helper's as much as a parent's.
void main() {
  late HomeCareHarness harness;
  final stockPath = HomeCareRoute.stockPathFor(Fixtures.householdId);

  setUp(() => harness = HomeCareHarness());
  tearDown(() => harness.close());

  Future<void> open(WidgetTester tester, {bool asHelper = false}) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      location: stockPath,
      view: asHelper ? HomeCareFixtures.helperView() : null,
    );
  }

  testWidgets('holds its layout while it loads', (tester) async {
    await open(tester);
    await tester.pump();
    expect(find.text(HomeCareStockCopy.stock), findsOneWidget);
    expect(find.text('Jik'), findsNothing);
  });

  testWidgets('what is running low comes first, said to be on the list', (
    tester,
  ) async {
    await open(tester);
    await harness.emit(
      tester,
      products: [
        HomeCareFixtures.bleach.copyWith(
          stock: StockLevel.low,
          stockChangedBy: Fixtures.thandiMemberId,
        ),
        HomeCareFixtures.soap,
      ],
    );
    expect(find.text(HomeCareStockCopy.runningOut), findsOneWidget);
    expect(find.text(HomeCareStockCopy.inTheCupboard), findsOneWidget);
    expect(find.text(HomeCareStockCopy.onTheList), findsOneWidget);
    expect(
      find.text(HomeCareStockCopy.markedBy('Thandi Helper')),
      findsOneWidget,
    );
    final low = tester.getTopLeft(find.text('Jik'));
    final full = tester.getTopLeft(find.text('Sunlight liquid'));
    expect(low.dy, lessThan(full.dy));
  });

  testWidgets('a helper marks a product low, in her own name', (tester) async {
    await open(tester, asHelper: true);
    await harness.emit(tester, products: const [HomeCareFixtures.bleach]);

    await tester.tap(
      find.bySemanticsLabel(
        HomeCareStockCopy.levelForReader('Jik', StockLevel.low),
      ),
    );
    await tester.pumpAndSettle();
    expect(harness.library.methods, ['setStock']);
    expect(harness.library.writes.single.$2, {
      'productId': 'jik',
      'level': StockLevel.low,
      'by': Fixtures.thandiMemberId,
    });
  });

  testWidgets('the level it is at already is not a button again', (
    tester,
  ) async {
    await open(tester);
    await harness.emit(tester, products: const [HomeCareFixtures.bleach]);
    await tester.tap(
      find.bySemanticsLabel(
        HomeCareStockCopy.levelForReader('Jik', StockLevel.full),
      ),
    );
    await tester.pumpAndSettle();
    expect(harness.library.writes, isEmpty);
  });

  testWidgets('a mark the rules refuse is said in words', (tester) async {
    await open(tester);
    await harness.emit(tester, products: const [HomeCareFixtures.bleach]);
    harness.library.failWritesWith = const PermissionDeniedFailure();
    await tester.tap(
      find.bySemanticsLabel(
        HomeCareStockCopy.levelForReader('Jik', StockLevel.out),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
  });

  testWidgets('no products sends a parent to add them', (tester) async {
    await open(tester);
    await harness.emit(tester, products: const []);
    expect(find.text(HomeCareStockCopy.emptyTitle), findsOneWidget);
    await tester.tap(find.text(HomeCareStockCopy.openProducts));
    await tester.pumpAndSettle();
    expect(find.text(HomeCareLibraryCopy.productsSubtitle), findsOneWidget);
  });

  testWidgets('and tells a helper what it will be for', (tester) async {
    await open(tester, asHelper: true);
    await harness.emit(tester, products: const []);
    expect(find.text(HomeCareStockCopy.emptyHelperBody), findsOneWidget);
    expect(find.text(HomeCareStockCopy.openProducts), findsNothing);
  });

  testWidgets('says what went wrong in words, with a retry', (tester) async {
    await open(tester);
    harness.jobs.failJobsWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('says plainly when the switch is off', (tester) async {
    await open(tester);
    await harness.emit(tester);
    harness.flags.emit({'homeCareStock': false});
    await tester.pumpAndSettle();
    expect(find.text(HomeCareCopy.switchedOffTitle), findsOneWidget);
  });
}
