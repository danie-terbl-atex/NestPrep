import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/add_to_checkers/data/lunch_shop_preference.dart';
import '../features/add_to_checkers/data/secure_storage_retailer_preference.dart';
import '../features/add_to_pnp/data/callable_pnp_directory.dart';
import '../features/add_to_pnp/data/pnp_directory.dart';

/// Pick n Pay in the app-wide graph (add-to-pnp ADR-0001): the shop chosen
/// for lunches on this phone, and the five callables. Its catalogue is with
/// the others in `addToCheckersProviders`.
List<SingleChildWidget> addToPnpProviders() => [
  Provider<LunchShopPreference>(
    create: (context) => SecureStorageRetailerPreference(
      prefix: SecureStorageRetailerPreference.lunchShopPrefix,
    ),
  ),
  Provider<PnpDirectory>(
    create: (context) =>
        CallablePnpDirectory(context.read<FirebaseFunctions>()),
  ),
];
