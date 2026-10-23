import '../../../app/household_shell.dart';

/// Which tab a tour step needs on screen before it can spotlight anything
/// (welcome-tour ADR-0002). Lists is two places, so each list is its own.
enum TourPlace {
  today(HouseholdTab.today),
  lunch(HouseholdTab.lunch),
  meals(HouseholdTab.meals),
  todos(HouseholdTab.todos),
  groceries(HouseholdTab.groceries),
  more(HouseholdTab.more);

  const TourPlace(this.tab);

  final HouseholdTab tab;
}
