import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/accounts/data/account_repository.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/legal/data/bundled_legal_document_source.dart';
import '../features/legal/data/legal_document_source.dart';
import '../features/legal/model/legal_kind.dart';
import '../features/legal/state/consent_controller.dart';
import '../features/legal/state/legal_document_controller.dart';
import '../features/legal/state/licences_controller.dart';
import '../features/legal/ui/about_screen.dart';
import '../features/legal/ui/consent_screen.dart';
import '../features/legal/ui/legal_document_screen.dart';
import '../features/legal/ui/licence_detail_screen.dart';
import '../features/legal/ui/licences_screen.dart';
import '../shared/links/external_link_opener.dart';

/// About, the privacy policy, the terms, the licences and the consent step
/// (accounts ADR-0005) — top-level, outside the household shell, because a
/// person reads them before they have a household and while they are being
/// asked to agree. Spread into the route table by the account routes.
///
/// [source] is where the documents come from: the bundle in the app, a fake
/// in a test.
List<RouteBase> legalRoutes({LegalDocumentSource? source}) {
  final documents = source ?? BundledLegalDocumentSource();
  return [
    GoRoute(
      path: ConsentScreen.path,
      builder: (context, state) {
        final session = context.read<SessionController>();
        return ChangeNotifierProvider(
          create: (context) => ConsentController(
            accountRepository: context.read<AccountRepository>(),
            uid: session.uidOrEmpty,
            isUpdate: session.hasAcceptedEarlierLegal,
          ),
          child: const ConsentScreen(),
        );
      },
    ),
    GoRoute(
      path: AboutScreen.path,
      builder: (context, state) => const AboutScreen(),
    ),
    for (final kind in LegalKind.values)
      GoRoute(
        path: LegalDocumentScreen.pathFor(kind),
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => LegalDocumentController(
            source: documents,
            linkOpener: context.read<ExternalLinkOpener>(),
            kind: kind,
          ),
          child: const LegalDocumentScreen(),
        ),
      ),
    GoRoute(
      path: LicencesScreen.path,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => LicencesController(),
        child: const LicencesScreen(),
      ),
      routes: [
        GoRoute(
          path: ':${LicenceDetailScreen.packageParameter}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => LicencesController(),
            child: LicenceDetailScreen(
              package:
                  state.pathParameters[LicenceDetailScreen.packageParameter] ??
                  '',
            ),
          ),
        ),
      ],
    ),
  ];
}

/// Where a signed-in person who has still to agree belongs: the consent step,
/// or one of the pages it links to so they can read what they are agreeing
/// to first (accounts ADR-0005). Null leaves them where they are.
String? redirectForConsent(String location) {
  final readable = [
    ConsentScreen.path,
    AboutScreen.path,
    LegalDocumentScreen.privacyPath,
    LegalDocumentScreen.termsPath,
    LicencesScreen.path,
  ];
  final isReadable = readable.any(
    (path) => location == path || location.startsWith('$path/'),
  );
  return isReadable ? null : ConsentScreen.path;
}
