import '../../todos/model/task_occurrence.dart';
import 'point_claim.dart';

/// What a child's job tile says about its stars (todos ADR-0003) — one
/// answer per tile, worked out once from the job and its claim, so the tile
/// only renders it (`FE-04`).
sealed class KidChoreNote {
  const KidChoreNote();

  /// The note for one job. [claim] is the job's claim if the trigger has
  /// written one, keyed like the completion.
  static KidChoreNote of(TaskOccurrence chore, PointClaim? claim) {
    final points = chore.task.points;
    if (points <= 0) return const NoStars();
    if (!chore.isDone) {
      // Sent back: the parent undid it — say so kindly, and what it is worth.
      return claim?.status == ClaimStatus.sentBack
          ? TryAgain(points)
          : Earns(points);
    }
    return switch (claim?.status) {
      ClaimStatus.awarded => Earned(claim?.points ?? points),
      ClaimStatus.pending => WaitingForGrownUp(claim?.points ?? points),
      // Ticked a moment ago: the server is still counting.
      _ => Counting(points),
    };
  }
}

/// An ordinary job, worth no stars.
final class NoStars extends KidChoreNote {
  const NoStars();
}

/// Worth [points] when it is done.
final class Earns extends KidChoreNote {
  const Earns(this.points);
  final int points;
}

/// A grown-up asked for another go; still worth [points].
final class TryAgain extends KidChoreNote {
  const TryAgain(this.points);
  final int points;
}

/// Done; the stars are on their way.
final class Counting extends KidChoreNote {
  const Counting(this.points);
  final int points;
}

/// Done, and a grown-up will check it before the [points] land.
final class WaitingForGrownUp extends KidChoreNote {
  const WaitingForGrownUp(this.points);
  final int points;
}

/// Done and paid.
final class Earned extends KidChoreNote {
  const Earned(this.points);
  final int points;
}
