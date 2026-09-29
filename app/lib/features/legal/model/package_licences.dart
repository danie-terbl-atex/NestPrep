import 'package:flutter/foundation.dart';

/// Every licence text one package or font ships with. A package can carry
/// several — a font and its code, a library and what it vendors.
@immutable
final class PackageLicences {
  const PackageLicences({required this.package, required this.texts});

  final String package;
  final List<String> texts;
}

/// Folds the registry's entries — each naming one or more packages — into
/// one row per package, sorted by name the way a person scans a list.
List<PackageLicences> groupLicences(Iterable<LicenseEntry> entries) {
  final byPackage = <String, List<String>>{};
  for (final entry in entries) {
    final text = entry.paragraphs
        .map((paragraph) => paragraph.text)
        .join('\n\n');
    for (final package in entry.packages) {
      byPackage.putIfAbsent(package, () => []).add(text);
    }
  }
  final names = byPackage.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [
    for (final name in names)
      PackageLicences(
        package: name,
        texts: List.unmodifiable(byPackage[name]!),
      ),
  ];
}
