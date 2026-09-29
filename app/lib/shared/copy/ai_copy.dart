import '../failure/app_failure.dart';

/// What any AI feature says when the model could not help (`FE-19`,
/// foundation ADR-0015). Shared, so reading a letter and planning a week
/// explain a spent month in the same words.
abstract final class AiCopy {
  static String problem(AiProblem problem) => switch (problem) {
    AiProblem.aiSwitchedOff =>
      'Reading with AI is paused for now. Please add these by hand.',
    AiProblem.aiLimitReached =>
      'Your household has used this month’s AI reads. They come back on '
          'the 1st — or add these by hand in the meantime.',
    AiProblem.aiUnavailable =>
      'The reading service did not answer. Give it a moment and try again.',
    AiProblem.aiUnreadable =>
      'That did not come back in a form NestPrep could use. Please try again.',
    AiProblem.aiDeclined =>
      'That could not be read. Try a photo of just the letter.',
  };

  /// How many reads are left this month, once a read has said.
  static String callsLeft(int calls) => switch (calls) {
    0 => 'That was this month’s last AI read.',
    1 => '1 AI read left this month.',
    _ => '$calls AI reads left this month.',
  };
}
