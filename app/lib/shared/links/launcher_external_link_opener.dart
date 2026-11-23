import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'external_link_opener.dart';

/// The platform's own handler for a link, outside the app — so a provider's
/// sign-in happens in the browser the person trusts, never in a web view
/// NestPrep controls (calendar ADR-0003).
final class LauncherExternalLinkOpener implements ExternalLinkOpener {
  const LauncherExternalLinkOpener();

  /// Android throws rather than answering false when no app takes the link —
  /// a `webcal://` subscription on a phone with no calendar app that knows the
  /// scheme. The exception's message carries the whole link, token included,
  /// so it must never reach the crash report.
  @override
  Future<bool> open(Uri link) async {
    try {
      return await launchUrl(link, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}
