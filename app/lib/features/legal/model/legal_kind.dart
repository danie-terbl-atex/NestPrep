/// The two documents a person agrees to, and where each is shipped.
enum LegalKind {
  privacy('assets/legal/privacy-policy.md'),
  terms('assets/legal/terms-of-service.md');

  const LegalKind(this.assetPath);

  final String assetPath;
}
