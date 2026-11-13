abstract final class AvatarStage {
  static const egg = 0;
  static const hatchling = 1;
  static const fledgling = 2;
  static const flyer = 3;

  static const all = [egg, hatchling, fledgling, flyer];

  static const fledglingStreak = 3;
  static const flyerStreak = 7;

  static int clamp(int stage) => stage.clamp(egg, flyer);

  static int forStars({required int earned, required int bestStreak}) {
    if (bestStreak >= flyerStreak) return flyer;
    if (bestStreak >= fledglingStreak) return fledgling;
    if (earned >= 1 || bestStreak >= 1) return hatchling;
    return egg;
  }
}

final class StageProgress {
  const StageProgress._({
    required this.stage,
    required this.next,
    required this.done,
    required this.needed,
  });

  factory StageProgress.of({
    required int stage,
    required int earned,
    required int bestStreak,
  }) => switch (stage) {
    AvatarStage.egg => StageProgress._(
      stage: stage,
      next: AvatarStage.hatchling,
      done: earned >= 1 || bestStreak >= 1 ? 1 : 0,
      needed: 1,
    ),
    AvatarStage.hatchling => StageProgress._(
      stage: stage,
      next: AvatarStage.fledgling,
      done: bestStreak.clamp(0, AvatarStage.fledglingStreak),
      needed: AvatarStage.fledglingStreak,
    ),
    AvatarStage.fledgling => StageProgress._(
      stage: stage,
      next: AvatarStage.flyer,
      done: bestStreak.clamp(0, AvatarStage.flyerStreak),
      needed: AvatarStage.flyerStreak,
    ),
    _ => const StageProgress._(
      stage: AvatarStage.flyer,
      next: null,
      done: AvatarStage.flyerStreak,
      needed: AvatarStage.flyerStreak,
    ),
  };

  final int stage;
  final int? next;
  final int done;
  final int needed;

  int get toGo => needed - done;

  double get fraction => needed == 0 ? 1 : done / needed;

  bool get isGrown => next == null;
}
