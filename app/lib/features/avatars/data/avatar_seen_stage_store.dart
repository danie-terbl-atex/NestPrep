abstract interface class AvatarSeenStageStore {
  Future<int?> seen(String householdId, String memberId);

  Future<void> markSeen(String householdId, String memberId, int stage);
}
