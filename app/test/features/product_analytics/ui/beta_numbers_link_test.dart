import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/product_analytics/data/beta_numbers_repository.dart';
import 'package:nestprep/features/product_analytics/state/beta_numbers_controller.dart';
import 'package:nestprep/features/product_analytics/ui/beta_numbers_link.dart';
import 'package:nestprep/features/product_analytics/ui/beta_numbers_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_product_analytics.dart';

/// The way in to the Beta numbers screen: there for a reader, absent for
/// everybody else, and it actually arrives (the vault lesson on a capability
/// finished everywhere except the screen).
void main() {
  const copy = AppCopy.productAnalytics;
  late FakeBetaNumbersRepository repository;

  setUp(() => repository = FakeBetaNumbersRepository());
  tearDown(() => repository.close());

  Future<void> pump(WidgetTester tester, {VoidCallback? onOpen}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: BetaNumbersLink(onOpen: onOpen)),
        ),
        GoRoute(
          path: BetaNumbersScreen.path,
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => BetaNumbersController(
              betaNumbersRepository: context.read<BetaNumbersRepository>(),
            ),
            child: const BetaNumbersScreen(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    return tester.pumpWidget(
      Provider<BetaNumbersRepository>.value(
        value: repository,
        child: MaterialApp.router(
          theme: nestThemeData(NestTheme.light()),
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgets('is not offered to an account without the reader claim', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text(copy.openLink), findsNothing);
  });

  testWidgets('is not offered when the claim cannot be checked', (
    tester,
  ) async {
    repository
      ..isReader = true
      ..failCanReadWith = const UnavailableFailure();
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text(copy.openLink), findsNothing);
  });

  testWidgets('is offered to a reader, and opens the numbers', (tester) async {
    repository.isReader = true;
    var opened = 0;
    await pump(tester, onOpen: () => opened += 1);
    await tester.pumpAndSettle();

    await tester.tap(find.text(copy.openLink));
    await tester.pump();
    await tester.pump();
    repository.emitWeeks(const []);
    await tester.pumpAndSettle();

    expect(opened, 1, reason: 'the sheet it sits in is told to close');
    expect(find.byType(BetaNumbersScreen), findsOneWidget);
    expect(find.text(copy.emptyTitle), findsOneWidget);
  });
}
