import '../../../shared/failure/app_failure.dart';
import 'letter_proposal.dart';

/// What reading one letter gave back: the events it proposed, and how many
/// AI calls the household has left this month (foundation ADR-0015).
final class LetterReading {
  const LetterReading({required this.proposals, required this.callsLeft});

  final List<LetterProposal> proposals;
  final int callsLeft;

  /// The callable's reply, parsed. A reply that is not the contract's shape
  /// is the model's answer arriving unreadable, and is said so — never cast
  /// (`ENG-09`). A single proposal that does not parse is left out.
  factory LetterReading.fromWire(Object? data) {
    if (data is! Map) throw const AiFailure(AiProblem.aiUnreadable);
    final proposals = data['proposals'];
    final callsLeft = data['callsLeft'];
    if (proposals is! List || callsLeft is! int) {
      throw const AiFailure(AiProblem.aiUnreadable);
    }
    return LetterReading(
      proposals: [for (final item in proposals) ?LetterProposal.fromWire(item)],
      callsLeft: callsLeft,
    );
  }
}
