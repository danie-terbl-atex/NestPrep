/// Every word budget mode says (lunch-box ADR-0007), `FE-19`. Amounts arrive
/// already formatted by `Money` — nothing here does arithmetic.
abstract final class LunchBudgetCopy {
  static const title = 'Lunch budget';
  static const subtitle = 'What the week’s boxes cost';

  // Locked, for a free household.
  static const lockedTitle = 'Lunches on a budget';
  static const lockedBody =
      'See what every box and the whole week cost, keep to a weekly budget, '
      'and get cheaper swaps your children will still eat. Budget mode is '
      'part of Premium.';
  static const seePremium = 'See Premium';

  // The meter.
  static const thisWeek = 'This week';
  static String spentOf(String spent, String budget) => '$spent of $budget';
  static String spentAtLeast(String spent) => 'At least $spent';
  static String spentOnly(String spent) => spent;
  static String left(String amount) => '$amount left for the week';
  static String nearly(String amount) => 'Nearly there — $amount left';
  static String over(String amount) =>
      '$amount over — a swap or two would do it';
  static const noBudget = 'No weekly budget yet.';
  static const setBudget = 'Set a weekly budget';
  static const changeBudget = 'Change the budget';
  static String meterLabel(String spent, String budget) =>
      'Spent $spent of a $budget weekly budget';

  // The budget sheet.
  static const budgetSheetTitle = 'Weekly lunch budget';
  static const budgetAmount = 'For every child’s boxes, each week';
  static const budgetHint = '250';
  static const budgetInvalid = 'Enter an amount between R1 and R100 000.';
  static const saveBudget = 'Save';
  static const removeBudget = 'No budget';

  // Per child.
  static String childWeek(String name) => '$name’s week';
  static String dayCost(String day, String amount) => '$day $amount';
  static const nothingPacked = 'Nothing packed this week';
  static String unpriced(int count) => count == 1
      ? '1 thing this week has no price yet, so the total is at least this.'
      : '$count things this week have no price yet, so the total is at least '
            'this.';
  static const priceThem = 'Add prices';

  // Swaps.
  static String swapsFor(String name) => 'Cheaper swaps for $name';
  static const noSwaps =
      'No cheaper swaps this week — or nothing packed from today has a '
      'price yet.';
  static String swapLine(String from, String to) => '$from → $to';
  static String swapSaves(String amount, int boxes) => boxes == 1
      ? 'Saves $amount on 1 box'
      : 'Saves $amount across $boxes boxes';
  static const swapWhy = 'Same part of the box, safe for them, eaten as well';
  static const swap = 'Swap';

  // Prices.
  static const pricesTitle = 'Prices';
  static const pricesSubtitle = 'What you pay, per box or per pack';
  static const allPrices = 'All prices';
  static const noPrice = 'No price yet';
  static String perBox(String amount) => '$amount a box';
  static String perPack(String amount, int boxes) => '$amount for $boxes boxes';
  static const priceSheetTitle = 'What does it cost?';
  static const byBox = 'Per box';
  static const byPack = 'Per pack';
  static const amountPerBox = 'Price for one box';
  static const amountPerPack = 'Price of the pack';
  static const amountHint = '12.50';
  static const packBoxes = 'How many boxes it does';
  static const packBoxesHint = '8';
  static const amountInvalid = 'Enter an amount like 12.50, up to R5 000.';
  static const boxesInvalid = 'Between 1 and 100 boxes.';
  static String worksOutAt(String amount) => 'Works out at $amount a box';
  static const savePrice = 'Save';
  static const removePrice = 'Remove the price';
}
