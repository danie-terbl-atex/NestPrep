import 'package:url_launcher/url_launcher.dart';

import 'document_opener.dart';

/// The platform's own handler for a file the app cannot render — a PDF viewer,
/// or the browser, which is what saves it to the phone.
///
/// The link is a Cloud Storage download URL, which authorises by possession
/// rather than by rule. It is handed straight to the platform and is never
/// shown, copied or shared (documents ADR-0001).
final class LauncherDocumentOpener implements DocumentOpener {
  const LauncherDocumentOpener();

  @override
  Future<bool> open(Uri link) =>
      launchUrl(link, mode: LaunchMode.externalApplication);
}
