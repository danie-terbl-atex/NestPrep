import 'package:url_launcher/url_launcher.dart';

import 'external_link_opener.dart';

/// The platform's own handler for a link, outside the app — so a provider's
/// sign-in happens in the browser the person trusts, never in a web view
/// NestPrep controls (calendar ADR-0003).
final class LauncherExternalLinkOpener implements ExternalLinkOpener {
  const LauncherExternalLinkOpener();

  @override
  Future<bool> open(Uri link) =>
      launchUrl(link, mode: LaunchMode.externalApplication);
}
