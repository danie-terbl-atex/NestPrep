import 'package:flutter/foundation.dart';

/// A hint the plan leans on, never a limit anything is refused by
/// (lunch-box ADR-0011): `thrifty` prefers what costs least where the
/// household has priced things (budget mode, lunch-box ADR-0007). The stored
/// name is the server's `PLAN_BUDGETS`.
enum PlanBudget { none, thrifty }

/// How a week is to be planned, as the parent chose it before asking.
@immutable
final class PlanWeekOptions {
  const PlanWeekOptions({
    required this.childIds,
    required this.includeDinners,
    required this.useWhatsInTheHouse,
    required this.budget,
  });

  /// Whose lunches to plan. Empty plans none — dinners alone are a plan too.
  final Set<String> childIds;
  final bool includeDinners;

  /// Prefer what the pantry holds (lunch-box ADR-0006).
  final bool useWhatsInTheHouse;
  final PlanBudget budget;

  bool get hasSomethingToPlan => childIds.isNotEmpty || includeDinners;

  PlanWeekOptions copyWith({
    Set<String>? childIds,
    bool? includeDinners,
    bool? useWhatsInTheHouse,
    PlanBudget? budget,
  }) => PlanWeekOptions(
    childIds: childIds ?? this.childIds,
    includeDinners: includeDinners ?? this.includeDinners,
    useWhatsInTheHouse: useWhatsInTheHouse ?? this.useWhatsInTheHouse,
    budget: budget ?? this.budget,
  );

  /// [childId] in or out.
  PlanWeekOptions toggleChild(String childId) => copyWith(
    childIds: childIds.contains(childId)
        ? ({...childIds}..remove(childId))
        : {...childIds, childId},
  );

  @override
  bool operator ==(Object other) =>
      other is PlanWeekOptions &&
      setEquals(other.childIds, childIds) &&
      other.includeDinners == includeDinners &&
      other.useWhatsInTheHouse == useWhatsInTheHouse &&
      other.budget == budget;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(childIds),
    includeDinners,
    useWhatsInTheHouse,
    budget,
  );
}
