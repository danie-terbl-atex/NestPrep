import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/app_version.dart';
import 'package:nestprep/features/legal/ui/about_screen.dart';
import 'package:nestprep/features/legal/ui/legal_document_screen.dart';
import 'package:nestprep/features/legal/ui/licence_detail_screen.dart';
import 'package:nestprep/features/legal/ui/licences_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_legal.dart';
import '../../../support/fake_link_opener.dart';

/// About, the two documents and the licences (accounts ADR-0005): what each
/// shows in every state, where each goes, and that each holds at 200% text in
/// dark on a 360-wide phone (`FE-13`, `FE-14`).
void main() {
  group('a legal document', () {
    testWidgets('shows its sections, its date and its gaps as gaps', (
      tester,
    ) async {
      await pumpLegal(tester, location: LegalDocumentScreen.privacyPath);
      expect(find.text(LegalCopy.privacyTitle), findsOneWidget);
      expect(find.text(LegalCopy.updated('2026-09-29')), findsOneWidget);
      expect(find.text(LegalCopy.version(1)), findsOneWidget);
      expect(
        find.textContaining('1. What we keep', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(LegalCopy.placeholder('legal entity name'))),
        ),
        findsOneWidget,
        reason: 'a screen reader hears a placeholder as unfinished',
      );
    });

    testWidgets('the terms are the terms', (tester) async {
      await pumpLegal(tester, location: LegalDocumentScreen.termsPath);
      expect(find.text(LegalCopy.termsTitle), findsOneWidget);
    });

    testWidgets('a link opens outside the app', (tester) async {
      final opener = FakeLinkOpener();
      await pumpLegal(
        tester,
        location: LegalDocumentScreen.privacyPath,
        linkOpener: opener,
      );
      await tester.tapOnText(find.textRange.ofSubstring('our site'));
      await tester.pumpAndSettle();
      expect(opener.opened, [Uri.parse('https://nestprep.app/privacy')]);
      expect(find.text(LegalCopy.linkWouldNotOpen), findsNothing);
    });

    testWidgets('a link the phone will not open says so', (tester) async {
      await pumpLegal(
        tester,
        location: LegalDocumentScreen.privacyPath,
        linkOpener: FakeLinkOpener()..opens = false,
      );
      await tester.tapOnText(find.textRange.ofSubstring('our site'));
      await tester.pumpAndSettle();
      expect(find.text(LegalCopy.linkWouldNotOpen), findsOneWidget);
    });

    testWidgets('a document that will not load offers a retry', (tester) async {
      final source = FakeLegalDocumentSource()
        ..failure = const UnavailableFailure();
      await pumpLegal(
        tester,
        location: LegalDocumentScreen.privacyPath,
        source: source,
      );
      expect(
        find.text(AppCopy.failure(const UnavailableFailure())),
        findsOneWidget,
      );

      source.failure = null;
      await tester.tap(find.text(AppCopy.retry));
      await tester.pumpAndSettle();
      expect(find.text(LegalCopy.version(1)), findsOneWidget);
    });
  });

  group('About', () {
    testWidgets('says which version this is and links to the rest', (
      tester,
    ) async {
      await pumpLegal(tester, location: AboutScreen.path);
      expect(
        find.text(LegalCopy.appVersion(AppVersion.name, AppVersion.build)),
        findsOneWidget,
      );
      expect(find.text(LegalCopy.aboutSupportAddress), findsOneWidget);

      await tester.tap(find.text(LegalCopy.termsTitle));
      await tester.pumpAndSettle();
      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      expect(find.text(LegalCopy.termsTitle), findsOneWidget);
    });

    testWidgets('opens the licences', (tester) async {
      await pumpLegal(tester, location: AboutScreen.path);
      await tester.scrollUntilVisible(
        find.text(LegalCopy.licencesTitle),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text(LegalCopy.licencesTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LegalCopy.licencesTitle));
      await tester.pumpAndSettle();
      expect(find.byType(LicencesScreen), findsOneWidget);
    });
  });

  group('Licences', () {
    setUp(() {
      LicenseRegistry.reset();
      LicenseRegistry.addLicense(
        () => Stream.fromIterable([
          const LicenseEntryWithLineBreaks(['provider'], 'MIT licence text'),
          const LicenseEntryWithLineBreaks(['Nunito'], 'SIL Open Font Licence'),
        ]),
      );
    });
    tearDown(LicenseRegistry.reset);

    testWidgets('lists every package and opens one', (tester) async {
      await pumpLegal(tester, location: LicencesScreen.path);
      expect(find.text('Nunito'), findsOneWidget);
      expect(find.text('provider'), findsOneWidget);
      expect(find.text(LegalCopy.licenceCount(1)), findsNWidgets(2));

      await tester.tap(find.text('Nunito'));
      await tester.pumpAndSettle();
      expect(find.byType(LicenceDetailScreen), findsOneWidget);
      expect(find.text('SIL Open Font Licence'), findsOneWidget);
    });

    testWidgets('a package this build does not carry is empty, not broken', (
      tester,
    ) async {
      await pumpLegal(tester, location: LicencesScreen.pathFor('nothing'));
      expect(find.text(LegalCopy.licencesEmptyTitle), findsOneWidget);
    });

    testWidgets('no licences at all says so', (tester) async {
      LicenseRegistry.reset();
      await pumpLegal(tester, location: LicencesScreen.path);
      expect(find.text(LegalCopy.licencesEmptyTitle), findsOneWidget);
    });
  });

  group('survives dark at 200% text on a 360-wide phone', () {
    setUp(() {
      LicenseRegistry.reset();
      LicenseRegistry.addLicense(
        () => Stream.value(
          const LicenseEntryWithLineBreaks(['a_rather_long_package_name'], 'x'),
        ),
      );
    });
    tearDown(LicenseRegistry.reset);

    for (final location in [
      LegalDocumentScreen.privacyPath,
      AboutScreen.path,
      LicencesScreen.path,
      LicencesScreen.pathFor('a_rather_long_package_name'),
    ]) {
      testWidgets(location, (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await pumpLegal(
          tester,
          location: location,
          brightness: Brightness.dark,
          textScale: 2,
        );
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
