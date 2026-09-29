/// What deleting the account would do to one household (accounts ADR-0006).
/// The server decides it; the app only shows it and sends back the endings
/// the person agreed to.
enum HouseholdDeletionOutcome {
  /// Somebody else can run it; the person simply goes.
  leave,

  /// The person is the last admin; another adult becomes admin.
  handOver,

  /// The person is the last adult; the household and everything in it goes.
  end;

  static HouseholdDeletionOutcome? fromName(Object? name) =>
      values.where((value) => value.name == name).firstOrNull;
}

final class HouseholdDeletionPreview {
  const HouseholdDeletionPreview({
    required this.householdId,
    required this.name,
    required this.outcome,
    required this.othersLosingAccess,
    required this.hasPremium,
    this.successorName,
  });

  final String householdId;
  final String name;
  final HouseholdDeletionOutcome outcome;

  /// Who becomes admin, on a hand-over.
  final String? successorName;

  /// Other people and kid devices that lose the household when it ends.
  final int othersLosingAccess;
  final bool hasPremium;
}

final class DeletionPreview {
  const DeletionPreview({
    required this.households,
    required this.renewingSubscriptions,
  });

  final List<HouseholdDeletionPreview> households;

  /// Store subscriptions this person pays for that keep renewing until they
  /// cancel them in the store — deleting the account cannot stop a store's
  /// billing (subscriptions ADR-0001).
  final int renewingSubscriptions;

  /// The households the person is agreeing to end by confirming.
  List<String> get endingHouseholdIds => [
    for (final household in households)
      if (household.outcome == HouseholdDeletionOutcome.end)
        household.householdId,
  ];
}
