import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/legal_routes.dart';
import 'package:nestprep/features/accounts/data/account_repository.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/legal/data/legal_document_source.dart';
import 'package:nestprep/features/legal/model/legal_document.dart';
import 'package:nestprep/features/legal/model/legal_document_parser.dart';
import 'package:nestprep/features/legal/model/legal_kind.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/links/external_link_opener.dart';
import 'package:provider/provider.dart';

import 'fake_auth.dart';
import 'fake_link_opener.dart';
import 'pump_screen.dart';

/// A short document in the legal subset, with one of everything a screen
/// has to draw: two heading levels, a paragraph with a link and a
/// placeholder, and bullets.
LegalDocument legalFixture({
  String title = 'Privacy Policy',
  int version = 1,
}) => parseLegalDocument(
  '---\ntitle: $title\nversion: $version\nupdated: 2026-09-29\n---\n'
  '**DRAFT FOR LEGAL REVIEW.** Provided by [legal entity name].\n'
  '\n'
  '## 1. What we keep\n'
  'Read more at [our site](https://nestprep.app/privacy).\n'
  '\n'
  '### Children\n'
  '- A child\'s profile, added by a parent.\n'
  '- Allergies and medication, seen by the family.\n',
);

/// The documents from memory. Set [failure] to make every load fail the way
/// an unreadable bundle would.
final class FakeLegalDocumentSource implements LegalDocumentSource {
  AppFailure? failure;
  final loaded = <LegalKind>[];

  @override
  Future<LegalDocument> load(LegalKind kind) async {
    loaded.add(kind);
    final failing = failure;
    if (failing != null) throw failing;
    return legalFixture(
      title: kind == LegalKind.privacy ? 'Privacy Policy' : 'Terms of Service',
    );
  }
}

/// Pumps the legal routes at [location], with somewhere to go back to.
Future<void> pumpLegal(
  WidgetTester tester, {
  required String location,
  FakeLegalDocumentSource? source,
  FakeLinkOpener? linkOpener,
  AccountRepository? accounts,
  SessionController? session,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  await pumpRouter(
    tester,
    router: GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Placeholder()),
        ...legalRoutes(source: source ?? FakeLegalDocumentSource()),
      ],
    ),
    providers: [
      Provider<ExternalLinkOpener>.value(value: linkOpener ?? FakeLinkOpener()),
      Provider<AccountRepository>.value(
        value: accounts ?? FakeAccountRepository(),
      ),
      if (session != null)
        ChangeNotifierProvider<SessionController>.value(value: session),
    ],
    brightness: brightness,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}
