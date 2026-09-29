import 'legal_block.dart';

/// A privacy policy or terms of service, parsed from the Markdown the app
/// ships and the website is built from — one source for both (accounts
/// ADR-0005).
final class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.version,
    required this.updated,
    required this.blocks,
  });

  final String title;

  /// What a person's acceptance is recorded against. It rises when the
  /// document changes in a way people must agree to again.
  final int version;

  /// `YYYY-MM-DD`, as written in the document — a date a person reads, not an
  /// instant (`ENG-21`).
  final String updated;
  final List<LegalBlock> blocks;
}
