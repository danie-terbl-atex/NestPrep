import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'helper_language.dart';

/// The id a translation is cached under (home-care ADR-0006):
/// `{sha256 of the text, hex}_{code}` — the same id the Function writes, so
/// the phone reads the cache (its own offline copy included) before it asks.
/// `helper_language_test.dart` holds the vectors the Function's test
/// holds too.
String translationIdOf(String text, HelperLanguage language) =>
    '${sha256.convert(utf8.encode(text))}_${language.code}';
