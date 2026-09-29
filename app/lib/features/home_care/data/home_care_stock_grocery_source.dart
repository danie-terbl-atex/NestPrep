import '../../../shared/copy/home_care_stock_copy.dart';
import '../../groceries/data/grocery_suggestion_source.dart';
import '../../groceries/model/grocery_need.dart';
import '../../groceries/model/grocery_need_reason.dart';
import '../../household/model/household_area.dart';
import '../../lunch_box/model/lunch_week.dart';
import 'home_care_library_repository.dart';

/// Home care's products running low or out, as grocery needs (home-care
/// ADR-0005, groceries ADR-0004) — the stock tracker plugged into the one
/// provenance the list knows.
///
/// The server's `addLowStockToGroceries` already writes the line the moment a
/// product is marked, whoever marked it and whether or not they were online;
/// this is the same need seen from the list, so *From this week's plans*
/// shows why it is there and *keep in step* keeps it rather than taking it
/// off as something no plan asks for. The reason is the same words the
/// server wrote.
final class HomeCareStockGrocerySource implements GrocerySuggestionSource {
  const HomeCareStockGrocerySource(this._library);

  final HomeCareLibraryRepository _library;

  @override
  String get id => 'homeCareStock';

  @override
  HouseholdArea get area => HouseholdArea.homeCare;

  @override
  Stream<List<GroceryNeed>> watchNeeds(String householdId, LunchWeek week) =>
      _library
          .watchProducts(householdId)
          .map(
            (products) => [
              for (final product in products)
                if (product.stock.isRunningOut &&
                    product.name.trim().isNotEmpty)
                  GroceryNeed(
                    name: product.name,
                    reason: const LabelledReason(HomeCareStockCopy.runningOut),
                  ),
            ],
          );
}
