import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/legal/data/bundled_legal_document_source.dart';
import 'package:nestprep/features/legal/model/legal_kind.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The bundle half of reading a legal document: the shipped file, parsed,
/// and a failure as a failure the screen can say something about.
void main() {
  test('reads each shipped document from the bundle', () async {
    final source = BundledLegalDocumentSource(bundle: _DiskBundle());
    for (final kind in LegalKind.values) {
      final document = await source.load(kind);
      expect(document.blocks, isNotEmpty, reason: kind.name);
    }
  });

  test('an unreadable document is an AppFailure, never a raw error', () {
    final source = BundledLegalDocumentSource(
      bundle: _DiskBundle(broken: true),
    );
    expect(source.load(LegalKind.terms), throwsA(isA<UnknownFailure>()));
  });

  test('a document that does not parse is one too', () {
    final source = BundledLegalDocumentSource(
      bundle: _DiskBundle(replacement: 'not a legal document'),
    );
    expect(source.load(LegalKind.privacy), throwsA(isA<UnknownFailure>()));
  });
}

/// The asset bundle, read from the files it is built from.
final class _DiskBundle extends CachingAssetBundle {
  _DiskBundle({this.broken = false, this.replacement});

  final bool broken;
  final String? replacement;

  @override
  Future<ByteData> load(String key) async {
    if (broken) throw FlutterError('Unable to load asset: $key');
    final text = replacement ?? File(key).readAsStringSync();
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}
