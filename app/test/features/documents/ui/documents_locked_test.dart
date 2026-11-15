import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nestprep/app/documents_route.dart';
import 'package:nestprep/features/documents/ui/document_library_screen.dart';
import 'package:nestprep/features/documents/ui/vault_lock_screen.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/copy/vault_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_documents.dart';
import '../../../support/pump_subscriptions.dart';

/// Documents is Premium in full (subscriptions ADR-0008): a household without
/// it meets every address under the shell locked, never hidden — the vaults
/// included, before the phone's own lock is asked for and with nothing behind
/// the place listening.
void main() {
  late DocumentsFakes fakes;

  setUp(() => fakes = DocumentsFakes());
  tearDown(() => fakes.close());

  const id = Fixtures.householdId;
  final places = {
    'the library': DocumentsRoute.pathFor(id),
    'a folder': DocumentsRoute.folderPathFor(id, 'school'),
    'search': DocumentsRoute.searchPathFor(id, expiringSoon: true),
    'the vaults': DocumentsRoute.vaultPathFor(id),
    'one person’s vault': DocumentsRoute.vaultPersonPathFor(
      id,
      Fixtures.kidMemberId,
    ),
    'the vault log': DocumentsRoute.vaultLogPathFor(id),
    'shared links': DocumentsRoute.sharesPathFor(id),
    'offline copies': DocumentsRoute.offlinePathFor(id),
  };

  Future<SubscriptionHarness> openLocked(
    WidgetTester tester, {
    String? location,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final subscriptions = SubscriptionHarness();
    await pumpDocuments(
      tester,
      fakes: fakes,
      location: location ?? DocumentsRoute.pathFor(id),
      premium: false,
      also: subscriptions.providers,
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pumpAndSettle();
    return subscriptions;
  }

  for (final (place, location) in [
    ('the library', DocumentsRoute.pathFor(id)),
    ('the vaults', DocumentsRoute.vaultPathFor(id)),
  ]) {
    testWidgets(
      'back from $place, locked, returns to where it was opened from',
      (tester) async {
        const outside = '/outside';
        final subscriptions = SubscriptionHarness();
        await pumpDocuments(
          tester,
          fakes: fakes,
          location: outside,
          premium: false,
          also: subscriptions.providers,
          outside: [
            GoRoute(
              path: outside,
              builder: (context, state) => const Scaffold(body: Text(outside)),
            ),
          ],
        );
        await tester.pumpAndSettle();
        unawaited(
          GoRouter.of(tester.element(find.text(outside))).push(location),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PremiumLockedView), findsOneWidget);

        await tester.tap(find.bySemanticsLabel(AppCopy.back));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PremiumLockedView), findsNothing);
        expect(find.text(outside), findsOneWidget);
      },
    );
  }

  for (final MapEntry(key: place, value: location) in places.entries) {
    testWidgets('$place is locked without Premium: the phone’s lock is never '
        'asked for and nothing listens', (tester) async {
      await openLocked(tester, location: location);

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(find.text(AppCopy.documentsTitle), findsOneWidget);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.documents)),
        findsOneWidget,
      );
      expect(find.byType(VaultLockScreen), findsNothing);
      expect(find.text(VaultCopy.lockedTitle), findsNothing);
      expect(fakes.deviceLock.asked, 0);
      expect(fakes.vaults.watchedVaults, isEmpty);
      expect(fakes.shares.asked, isEmpty);
      expect(fakes.directory.syncCount, 0);
      expect(fakes.directory.opened, isEmpty);
    });
  }

  testWidgets('with Premium the library opens', (tester) async {
    await pumpDocuments(
      tester,
      fakes: fakes,
      location: DocumentsRoute.pathFor(id),
    );
    answerLibrary(fakes);
    await tester.pumpAndSettle();

    expect(find.byType(DocumentLibraryScreen), findsOneWidget);
    expect(find.byType(PremiumLockedView), findsNothing);
  });

  testWidgets('See Premium opens the paywall on documents', (tester) async {
    final subscriptions = await openLocked(tester);

    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallPage), findsOneWidget);
    expect(
      subscriptions.paywallOpens.opened.single.trigger,
      PremiumFeature.documents,
    );
  });

  testWidgets('a link straight to a locked vault has no back button to a '
      'place that is not there', (tester) async {
    await openLocked(tester, location: DocumentsRoute.vaultPathFor(id));
    expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
  });

  testWidgets('the locked place and its paywall hold in dark at 200% text on '
      'a 360-wide phone', (tester) async {
    onASmallPhone(tester);

    await openLocked(
      tester,
      location: DocumentsRoute.vaultPathFor(id),
      brightness: Brightness.dark,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(PremiumLockedView), findsOneWidget);

    await tester.ensureVisible(find.text(SubscriptionCopy.seePremium));
    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
