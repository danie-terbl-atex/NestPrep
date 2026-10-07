import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/checkers_product.dart';
import 'checkers_failure_mapper.dart';
import 'product_match_ranker.dart';

final class CallableProductMatchRanker implements ProductMatchRanker {
  const CallableProductMatchRanker(this._functions);

  static const callable = 'rankProductMatches';
  static const maxProducts = 8;

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, double>> rank({
    required String householdId,
    required String item,
    required List<CheckersProduct> products,
  }) async {
    final Object? data;
    try {
      data = (await _functions.httpsCallable(callable).call<Object?>({
        'householdId': householdId,
        'item': item,
        'products': [
          for (final product in products.take(maxProducts))
            {
              'productId': product.id,
              'name': product.name,
              'brand': product.brand,
              'priceCents': product.price.cents,
            },
        ],
      })).data;
    } on FirebaseFunctionsException catch (error) {
      throw failureFromCheckersCallable(error);
    }
    if (data case {'ranked': final List<Object?> ranked}) {
      return {
        for (final entry in ranked)
          if (entry case {'productId': final String id, 'fit': final num fit})
            id: fit.toDouble(),
      };
    }
    throw UnknownFailure(StateError('$callable answered an unexpected shape'));
  }
}
