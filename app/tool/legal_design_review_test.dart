import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/legal/data/legal_document_source.dart';
import 'package:nestprep/features/legal/model/legal_document.dart';
import 'package:nestprep/features/legal/model/legal_document_parser.dart';
import 'package:nestprep/features/legal/model/legal_kind.dart';
import 'package:nestprep/features/legal/state/consent_controller.dart';
import 'package:nestprep/features/legal/state/legal_document_controller.dart';
import 'package:nestprep/features/legal/ui/about_screen.dart';
import 'package:nestprep/features/legal/ui/consent_screen.dart';
import 'package:nestprep/features/legal/ui/legal_document_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_auth.dart';
import '../test/support/fake_link_opener.dart';
import 'review_press.dart';

/// The consent step, the privacy policy as shipped, and About, in both
/// themes (accounts ADR-0005). Pictures to look at rather than assertions:
/// regenerate with
///
///     flutter test tool/legal_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('consent-$theme', (tester) async {
      final accounts = FakeAccountRepository();
      addTearDown(accounts.close);
      final controller = ConsentController(
        accountRepository: accounts,
        uid: 'uid-sam',
        isUpdate: false,
      )..setAdult(value: true);
      await captureScreen(
        tester,
        'consent-$theme',
        brightness: brightness,
        screen: ChangeNotifierProvider.value(
          value: controller,
          child: const ConsentScreen(),
        ),
        providers: const [],
        emit: () async {},
        // The ticks and the button, which is the part being decided on.
        act: () =>
            tester.drag(find.byType(Scrollable).first, const Offset(0, -2000)),
      );
    });

    testWidgets('privacy-policy-$theme', (tester) async {
      await captureScreen(
        tester,
        'privacy-policy-$theme',
        brightness: brightness,
        screen: ChangeNotifierProvider(
          create: (_) => LegalDocumentController(
            source: _ShippedDocuments(),
            linkOpener: FakeLinkOpener(),
            kind: LegalKind.privacy,
          ),
          child: const LegalDocumentScreen(),
        ),
        providers: const [],
        emit: () async {},
      );
    });

    testWidgets('about-$theme', (tester) async {
      await captureScreen(
        tester,
        'about-$theme',
        brightness: brightness,
        screen: const AboutScreen(),
        providers: const [],
        emit: () async {},
      );
    });
  }
}

/// The shipped documents, read straight from disk: the asset bundle's load
/// never finishes under a test's fake clock, and the picture should be of the
/// real text.
final class _ShippedDocuments implements LegalDocumentSource {
  @override
  Future<LegalDocument> load(LegalKind kind) async =>
      parseLegalDocument(File(kind.assetPath).readAsStringSync());
}
