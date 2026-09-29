import '../../features/home_care/model/stock_level.dart';

/// Every word the stock tracker says (home-care ADR-0005, `FE-19`) —
/// exported through `home_care_copy.dart`.
abstract final class HomeCareStockCopy {
  static const stock = 'Stock';
  static const subtitle = 'Mark what is running low — it goes on the list';
  static const runningOut = 'Running low';
  static const inTheCupboard = 'In the cupboard';
  static const onTheList = 'On the grocery list';

  static String level(StockLevel level) => switch (level) {
    StockLevel.full => 'Full',
    StockLevel.half => 'Half',
    StockLevel.low => 'Low',
    StockLevel.out => 'Out',
  };

  /// What a screen reader says for one of a product's four buttons.
  static String levelForReader(String product, StockLevel level) =>
      '$product: ${HomeCareStockCopy.level(level).toLowerCase()}';

  static String markedBy(String name) => 'Marked by $name';

  static const emptyTitle = 'No products yet';
  static const emptyBody =
      'Add the products in your cupboard, then mark here what is running '
      'low. A low one goes straight onto the grocery list.';
  static const emptyHelperBody =
      'When the family adds its products, you can mark here what is running '
      'low, and it goes onto the grocery list.';
  static const openProducts = 'Add products';
}
