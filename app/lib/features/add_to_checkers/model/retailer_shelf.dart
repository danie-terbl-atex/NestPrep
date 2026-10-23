import 'package:flutter/foundation.dart';

/// What a shelf of a shop's catalogue is read from: at Checkers, one of its
/// own product lists — a carousel on a merchandised page — or a display
/// category from its department tree (lunch-box ADR-0013); at Pick n Pay, one
/// of its categories (lunch-box ADR-0026).
enum RetailerShelfKind { productList, displayCategory, pnpCategory }

/// One shelf of a catalogue, by the shop's own id: a 24-hex id at Checkers,
/// a category code such as `lunch-box-snacks-1664414929` at Pick n Pay.
@immutable
final class RetailerShelf {
  const RetailerShelf.productList(this.id)
    : kind = RetailerShelfKind.productList;

  const RetailerShelf.displayCategory(this.id)
    : kind = RetailerShelfKind.displayCategory;

  const RetailerShelf.pnpCategory(this.id)
    : kind = RetailerShelfKind.pnpCategory;

  final RetailerShelfKind kind;
  final String id;

  static final _checkersId = RegExp(r'^[0-9a-f]{24}$');
  static final _pnpCode = RegExp(r'^[a-z0-9-]{3,120}$');

  /// Whether [id] looks like a Checkers catalogue id at all.
  static bool isId(String id) => _checkersId.hasMatch(id);

  /// Whether [code] looks like a Pick n Pay category code at all.
  static bool isPnpCode(String code) => _pnpCode.hasMatch(code);

  @override
  bool operator ==(Object other) =>
      other is RetailerShelf && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}
