import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/legal/model/legal_block.dart';
import 'package:nestprep/features/legal/model/legal_document_parser.dart';
import 'package:nestprep/features/legal/model/legal_kind.dart';
import 'package:nestprep/features/legal/model/legal_versions.dart';

/// The documents the app ships, read the way the app reads them (accounts
/// ADR-0005). A document that stops parsing would open on a phone as an
/// error, and a version that has moved without `LegalVersions` would ask
/// nobody to agree to what changed — both are caught here instead.
void main() {
  for (final kind in LegalKind.values) {
    group(kind.name, () {
      final document = parseLegalDocument(
        File(kind.assetPath).readAsStringSync(),
      );

      test('parses, and has something in it', () {
        expect(document.title, isNotEmpty);
        expect(document.blocks.whereType<LegalHeading>(), isNotEmpty);
        expect(document.blocks.length, greaterThan(10));
      });

      test('is the version this build asks people to accept', () {
        final expected = switch (kind) {
          LegalKind.privacy => LegalVersions.privacy,
          LegalKind.terms => LegalVersions.terms,
        };
        expect(
          document.version,
          expected,
          reason:
              'raise `LegalVersions` with the document — that is what asks '
              'every account to agree again',
        );
      });

      test('says it is a draft while it still has gaps in it', () {
        final source = File(kind.assetPath).readAsStringSync();
        final hasPlaceholders = RegExp(r'\[[^\]]+\](?!\()').hasMatch(source);
        if (hasPlaceholders) expect(source, contains('DRAFT'));
      });
    });
  }
}
