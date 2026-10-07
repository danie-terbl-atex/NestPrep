import '../model/checkers_product.dart';

/// How well each product fits a grocery line, 0 to 1, by product id
/// (foundation ADR-0021).
abstract interface class ProductMatchRanker {
  Future<Map<String, double>> rank({
    required String householdId,
    required String item,
    required List<CheckersProduct> products,
  });
}
