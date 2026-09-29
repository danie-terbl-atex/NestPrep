/// Where a cleaning job is in its loop (home-care ADR-0001). The rules allow
/// only these moves: assigned → inProgress → submitted → approved, and
/// submitted → sentBack → inProgress → submitted again.
enum JobStatus {
  assigned,
  inProgress,
  submitted,
  approved,
  sentBack;

  /// With the helper: steps can be ticked and the job handed in.
  bool get isWithHelper =>
      this == assigned || this == inProgress || this == sentBack;

  /// Waiting for a parent to look at the after photo.
  bool get isWaitingForReview => this == submitted;

  bool get isDone => this == approved;
}
