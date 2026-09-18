/// Who a task or an event is for, and the one rule that says an empty list
/// means everybody.
///
/// It reads like a convenience and it is not: "nobody named" meaning "anybody"
/// rather than "nobody" is a product decision, taken twice in the same words —
/// todos ADR-0001 ("one or more assignees, empty = anyone") and calendar
/// ADR-0001. *Somebody take the bins out* is a real task with no assignee, and
/// a list that filtered it out of everyone's day would be wrong for exactly the
/// task people most need reminding of.
///
/// It was written three times before this existed: on `Task`, on
/// `TaskOccurrence` and on `HouseholdEvent`. The `Task` pair was never called,
/// which is the worse half of the problem — a dead copy of a live rule is the
/// one that does not get fixed when the rule changes (`ENG-01`, `ENG-02`).
abstract final class MemberAudience {
  /// Nobody is named, so it is for the household.
  static bool isEveryone(List<String> memberIds) => memberIds.isEmpty;

  /// Whether [memberId] should see this. Everyone sees what names nobody.
  static bool includes(List<String> memberIds, String memberId) =>
      isEveryone(memberIds) || memberIds.contains(memberId);
}
