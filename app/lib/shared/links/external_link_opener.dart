/// Hands a link to whatever on the phone opens it — the browser for a
/// provider's sign-in page, the calendar app for a `webcal://` subscription.
///
/// Behind an interface because a widget test has no browser, and because "the
/// phone would not open it" is a state the screen has to say something true
/// about (`FE-08`). The one opener for the app: documents' download links use
/// it too (documents' `DocumentOpener` twin was folded into it at the merge,
/// `ENG-01`).
abstract interface class ExternalLinkOpener {
  /// Opens [link] outside NestPrep. False when nothing on the phone took it.
  Future<bool> open(Uri link);
}
