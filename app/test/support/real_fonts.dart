import 'dart:convert';

import 'package:flutter/services.dart';

/// Every font the app ships, read from the bundle's own manifest — the type
/// family *and* the icon font. A test renders in Ahem by default, so without
/// this the screenshots are black boxes where the words and the icons should
/// be, which is the opposite of useful for a design review.
Future<void> loadEveryFont() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  for (final entry in manifest.cast<Map<String, Object?>>()) {
    final family = entry['family'] as String?;
    final assets = (entry['fonts'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    if (family == null || assets.isEmpty) continue;
    final loader = FontLoader(family);
    for (final asset in assets) {
      final path = asset['asset'] as String?;
      if (path != null) loader.addFont(rootBundle.load(path));
    }
    // A family the bundle names but does not carry — cupertino_icons is one —
    // must not take the whole press down with it.
    try {
      await loader.load();
    } on Exception {
      continue;
    }
  }
}
