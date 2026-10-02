import 'package:flutter/foundation.dart';

/// What a shelf of the Sixty60 catalogue is read from (lunch-box ADR-0013):
/// one of Checkers' own product lists — a carousel on a merchandised page —
/// or a display category from its department tree.
enum CheckersShelfKind { productList, displayCategory }

/// One shelf of the catalogue, by its 24-hex id.
@immutable
final class CheckersShelf {
  const CheckersShelf.productList(this.id)
    : kind = CheckersShelfKind.productList;

  const CheckersShelf.displayCategory(this.id)
    : kind = CheckersShelfKind.displayCategory;

  final CheckersShelfKind kind;
  final String id;

  static final _id = RegExp(r'^[0-9a-f]{24}$');

  /// Whether [id] looks like a catalogue id at all.
  static bool isId(String id) => _id.hasMatch(id);

  @override
  bool operator ==(Object other) =>
      other is CheckersShelf && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}
