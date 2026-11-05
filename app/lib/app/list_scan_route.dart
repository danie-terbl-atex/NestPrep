import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/groceries/data/grocery_repository.dart';
import '../features/list_scan/data/callable_list_scan_reader.dart';
import '../features/list_scan/data/device_list_photo_picker.dart';
import '../features/list_scan/data/list_photo_picker.dart';
import '../features/list_scan/data/list_scan_reader.dart';
import '../features/list_scan/state/list_scan_controller.dart';
import '../features/list_scan/ui/list_scan_screen.dart';
import '../features/plan_week/data/shop_week_groceries.dart';
import '../features/recipes/data/recipe_groceries.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'viewer_member.dart';

/// Snap a shopping list (list-scan ADR-0001), pushed over the grocery list
/// so back returns there (`FE-17`). The way in is hidden while the flag is
/// off; the route stays, and the server refuses on the same flag.
abstract final class ListScanRoute {
  static const segment = 'scan';
  static final path =
      '${HouseholdRoute.path}/${HouseholdTab.groceries.segment}/$segment';

  static String pathFor(String householdId) =>
      '${HouseholdRoute.pathFor(householdId, HouseholdTab.groceries)}/$segment';
}

List<SingleChildWidget> listScanProviders() => [
  Provider<ListScanReader>(
    create: (context) =>
        CallableListScanReader(context.read<FirebaseFunctions>()),
  ),
  Provider<ListPhotoPicker>(create: (context) => DeviceListPhotoPicker()),
];

GoRoute listScanRoute() => GoRoute(
  path: ListScanRoute.path,
  builder: (context, state) {
    final householdId = HouseholdRoute.idFrom(state);
    final memberId = viewerMemberIdOf(context);
    final groceries = context.read<GroceryRepository>();
    return ChangeNotifierProvider(
      create: (context) => ListScanController(
        listScanReader: context.read<ListScanReader>(),
        listPhotoPicker: context.read<ListPhotoPicker>(),
        groceries: RecipeGroceries(
          groceryRepository: groceries,
          matched: ShopWeekGroceries(
            groceryRepository: groceries,
            householdId: householdId,
            memberId: memberId,
          ),
          householdId: householdId,
          memberId: memberId,
        ),
        householdId: householdId,
      ),
      child: ListScanScreen(memberId: memberId),
    );
  },
);
