/// Hands a link to whatever on the phone opens it — the browser for a
/// provider's sign-in page, the calendar app for a `webcal://` subscription.
///
/// Behind an interface because a widget test has no browser, and because "the
/// phone would not open it" is a state the screen has to say something true
/// about (`FE-08`). Documents has a twin, `DocumentOpener`, from before this
/// existed; moving it onto this is recorded in calendar phase 2's outstanding
/// work (`ENG-02`, `ENG-25`).
abstract interface class ExternalLinkOpener {
  /// Opens [link] outside NestPrep. False when nothing on the phone took it.
  Future<bool> open(Uri link);
}
