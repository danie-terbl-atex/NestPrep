import '../../features/chore_points/model/kid_chore_note.dart';
import '../../features/chore_points/model/point_entry.dart';
import '../../features/chore_points/model/reward.dart';
import '../../features/chore_points/model/reward_request.dart';
import '../failure/app_failure.dart';

/// Every user-facing string of stars and rewards (todos ADR-0003), beside
/// `AppCopy` rather than inside it (`FE-19`). `AppCopy.failure` reads
/// [problem], so a refusal is still turned into words in one place.
///
/// Two voices, as with kid sign-in: a parent's, which is the app's usual one,
/// and a child's — short, warm, never blaming. A point is always a *star* to
/// both.
abstract final class PointsCopy {
  // ---- said to both ----
  static String starsCount(int stars) => stars == 1 ? '1 star' : '$stars stars';

  // ---- the parent's screen ----
  static const screenTitle = 'Stars and rewards';
  static String waitingTitle(int count) =>
      count == 0 ? 'Waiting for you' : 'Waiting for you ($count)';
  static const waitingNone =
      'Nothing to look at. Chores that need a check, and treats the kids ask '
      'for, land here.';
  static const reviewApprove = 'Looks good';
  static const reviewSendBack = 'Send back';
  static const settleGiven = 'Given';
  static const settleNotNow = 'Not now';
  static String requestedBy(String? name, int cost) =>
      '${name ?? 'A child'} asked · ${starsCount(cost)}';

  static const kidsTitle = 'Stars';
  static const kidsEmpty =
      'Stars are for kids. Add a child under Household, with the role Kid, '
      'and give their chores stars.';
  static String earnedInAll(int earned) =>
      '${starsCount(earned)} earned in all';
  static String streakDays(int days) => '$days days in a row';
  static const history = 'History';
  static String historyTitle(String name) => 'Where $name’s stars came from';
  static const historyEmpty = 'No stars yet.';
  static String delta(int stars) => stars >= 0 ? '+$stars' : '−${-stars}';
  static String entryKind(EntryKind kind) => switch (kind) {
    EntryKind.chore => 'Chore done',
    EntryKind.choreUndone => 'Chore unticked',
    EntryKind.reward => 'Spent on a treat',
    EntryKind.rewardReturned => 'Treat declined, stars back',
  };

  static const spendFor = 'Spend stars';
  static String spendForTitle(String name, int stars) =>
      'Spend $name’s stars (${starsCount(stars)})';
  static String needsMore(int cost, int more) =>
      '${starsCount(cost)} · $more more needed';
  static String spendForConfirm(String name, String reward) =>
      'Give $name $reward?';
  static String spendForBody(int cost) =>
      '${starsCount(cost)} come off their stars now.';
  static const spendForYes = 'Give it';

  static const rewardsTitle = 'Rewards';
  static const rewardsEmpty =
      'No rewards yet. Add a treat the kids can save their stars for.';
  static const rewardAdd = 'Add a reward';
  static const rewardEdit = 'Edit reward';
  static const rewardTitleLabel = 'What is it?';
  static const rewardTitleHint = 'Ice cream after school';
  static const rewardCostLabel = 'How many stars?';
  static const rewardCostInvalid = 'A whole number from 1 to 10 000.';
  static const rewardIconLabel = 'Picture';
  static String iconName(RewardIcon icon) => switch (icon) {
    RewardIcon.gift => 'Gift',
    RewardIcon.treat => 'Treat',
    RewardIcon.iceCream => 'Ice cream',
    RewardIcon.screenTime => 'Screen time',
    RewardIcon.movie => 'Movie',
    RewardIcon.game => 'Game',
    RewardIcon.outing => 'Outing',
    RewardIcon.book => 'Book',
    RewardIcon.toy => 'Toy',
    RewardIcon.lateNight => 'Late night',
  };

  // ---- the task sheet and the to-do row ----
  static const choreStarsLabel = 'Stars for doing it';
  static const choreNoStars = 'None';
  static const choreNeedsApproval = 'A grown-up checks it first';
  static const choreNeedsSomebody =
      'Choose who earns the stars — a starred chore is for somebody.';
  static String starsChecked(int stars) => '${starsCount(stars)} · checked';

  // ---- the kid's home, read by a child ----
  static String kidStarsLabel(int stars) => stars == 1 ? 'star' : 'stars';
  static String kidStarsSaid(int stars, int streak) => [
    'You have ${starsCount(stars)}',
    if (streak >= 2) kidStreak(streak),
  ].join('. ');
  static String kidJustEarned(int stars) => '+${starsCount(stars)}! Brilliant.';
  static const kidNoStarsYet = 'Finish a starred job to earn some.';
  static String kidStreak(int days) => '$days days in a row!';

  /// What a job's tile says about its stars, or null for a job with none.
  static String? kidNote(KidChoreNote note) => switch (note) {
    NoStars() => null,
    Earns(:final points) => '+${starsCount(points)}',
    TryAgain(:final points) => 'Have another go · +${starsCount(points)}',
    Counting() => 'Counting your stars…',
    WaitingForGrownUp(:final points) =>
      'A grown-up will check · +${starsCount(points)}',
    Earned(:final points) => '${starsCount(points)} earned!',
  };

  static const kidShelfTitle = 'Treats to save for';
  static const kidShelfEmpty = 'No treats yet';
  static const kidShelfEmptyBody =
      'Ask a grown-up to add some treats you can spend your stars on.';
  static const kidGetIt = 'Get it!';
  static const kidEnoughStars = 'You have enough stars!';
  static String kidMoreToGo(int stars) => '${starsCount(stars)} more to go';
  static const kidAsked = 'Asked!';
  static String kidAskConfirm(String reward, int cost) =>
      'Spend ${starsCount(cost)} on $reward?';
  static const kidAskBody = 'A grown-up will give it to you.';
  static const kidAskYes = 'Yes please!';
  static const kidAskNotYet = 'Not yet';

  static const kidAskedTitle = 'What I asked for';
  static const kidRequestUntitled = 'A treat';
  static const kidRequestCounting = 'Counting…';
  static const kidRequestWaiting = 'A grown-up will sort it';
  static const kidRequestFulfilled = 'Yours!';
  static const kidRequestDeclined = 'Not this time · stars back';
  static String kidRequestRefused(RequestRefusal? refusal) => switch (refusal) {
    RequestRefusal.notEnoughPoints => 'Not enough stars yet',
    RequestRefusal.rewardGone => 'That treat has gone',
    RequestRefusal.notAKid || null => 'Ask a grown-up',
  };

  // ---- refusals ----
  static String problem(PointsProblem problem) => switch (problem) {
    PointsProblem.notFamily =>
      'Only a parent can give stars or hand over treats.',
    PointsProblem.claimNotFound =>
      'That chore is not waiting any more — it may have been unticked.',
    PointsProblem.requestNotFound => 'That request is no longer there.',
    PointsProblem.alreadySettled => 'Somebody has already dealt with that one.',
  };
}
