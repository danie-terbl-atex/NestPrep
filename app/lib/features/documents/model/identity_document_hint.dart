/// Whether a document reads as an identity document — an ID, a passport, a
/// birth certificate, a driving licence — from its name and tags, so the app
/// can ask twice before sending one outside the household (documents
/// ADR-0006).
///
/// A nudge, not a rule: who may share at all is the server's. It errs towards
/// asking, because a second tap costs less than a passport in a group chat.
abstract final class IdentityDocumentHint {
  static final _identity = RegExp(
    r'\b(id|ids|identity|passports?|birth ?certificates?|licen[cs]e|'
    r'driver.?s licen[cs]e|smart ?id|id ?card|id ?book)\b',
    caseSensitive: false,
  );

  static bool looksLikeIdentity({
    required String name,
    required List<String> tags,
  }) => [name, ...tags].any(_identity.hasMatch);
}
