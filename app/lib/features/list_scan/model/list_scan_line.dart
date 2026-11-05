import 'package:flutter/foundation.dart';

/// One thing the photo said to buy, as the member is reviewing it: nothing
/// is on the grocery list until they add it (list-scan ADR-0001).
@immutable
final class ListScanLine {
  const ListScanLine({
    required this.key,
    required this.name,
    this.quantity,
    this.isIncluded = true,
  });

  /// Its place in what the photo read; stable while the list is edited.
  final int key;
  final String name;

  /// How much, in the list's own words — null when it gave none.
  final String? quantity;
  final bool isIncluded;

  ListScanLine toggled() => ListScanLine(
    key: key,
    name: name,
    quantity: quantity,
    isIncluded: !isIncluded,
  );

  ListScanLine changed({required String name, required String? quantity}) =>
      ListScanLine(key: key, name: name, quantity: quantity);
}
