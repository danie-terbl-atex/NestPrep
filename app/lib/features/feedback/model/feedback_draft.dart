/// The vocabularies are closed in `rules/firestore/root/feedback.rules` and
/// read by the admin tools (feedback ADR-0001); a new value goes there too.
enum FeedbackKind { problem, praise, idea }

enum FeedbackArea {
  today,
  calendar,
  lunch,
  meals,
  groceries,
  todos,
  documents,
  care,
  family,
  account,
}

final class FeedbackDraft {
  const FeedbackDraft({
    required this.kind,
    required this.message,
    required this.mayContact,
    this.area,
    this.screen,
    this.householdId,
  });

  static const maxLength = 2000;

  final FeedbackKind kind;
  final String message;
  final bool mayContact;
  final FeedbackArea? area;

  /// The route pattern the person came from, never a filled-in path.
  final String? screen;
  final String? householdId;
}

enum FeedbackDelivery { delivered, queued }
