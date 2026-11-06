import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/add_to_checkers/data/callable_checkers_directory.dart';
import '../features/add_to_checkers/data/callable_product_match_ranker.dart';
import '../features/add_to_checkers/data/checkers_area_preference.dart';
import '../features/add_to_checkers/data/checkers_directory.dart';
import '../features/add_to_checkers/data/http_checkers_catalogue.dart';
import '../features/add_to_checkers/data/match_as_you_type_preference.dart';
import '../features/add_to_checkers/data/product_match_ranker.dart';
import '../features/add_to_checkers/data/retailer_catalogues.dart';
import '../features/add_to_checkers/data/retailer_preference.dart';
import '../features/add_to_checkers/data/secure_storage_checkers_area_preference.dart';
import '../features/add_to_checkers/data/secure_storage_retailer_preference.dart';
import '../features/add_to_pnp/data/http_pnp_catalogue.dart';
import '../features/add_to_woolworths/data/http_woolworths_catalogue.dart';
import '../features/groceries/model/product_match.dart';

/// Checkers in the app-wide graph (the Checkers build contract): every
/// shop's catalogue the phone searches itself — app-wide so its store and
/// search memory lasts the whole run — the area and the shop chosen on this
/// phone, and the five callables. Its own list, spread into `appProviders`.
List<SingleChildWidget> addToCheckersProviders() => [
  Provider<RetailerCatalogues>(
    create: (context) => RetailerCatalogues({
      ProductRetailer.checkers: HttpCheckersCatalogue(),
      ProductRetailer.pickNPay: HttpPnpCatalogue(),
      ProductRetailer.woolworths: HttpWoolworthsCatalogue(),
    }),
  ),
  Provider<CheckersAreaPreference>(
    create: (context) => SecureStorageCheckersAreaPreference(),
  ),
  Provider<RetailerPreference>(
    create: (context) => SecureStorageRetailerPreference(),
  ),
  Provider<MatchAsYouTypePreference>(
    create: (context) => SecureStorageRetailerPreference(),
  ),
  Provider<CheckersDirectory>(
    create: (context) =>
        CallableCheckersDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<ProductMatchRanker>(
    create: (context) =>
        CallableProductMatchRanker(context.read<FirebaseFunctions>()),
  ),
];
