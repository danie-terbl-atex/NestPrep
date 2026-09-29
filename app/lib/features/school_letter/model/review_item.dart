import 'package:flutter/foundation.dart';

import 'letter_proposal.dart';

/// One line of the review list: a proposal, and whether the parent means to
/// add it. Every line starts ticked — the letter is why they are here — and
/// nothing is added until they confirm (calendar ADR-0005).
@immutable
final class ReviewItem {
  const ReviewItem({
    required this.key,
    required this.proposal,
    this.isTicked = true,
  });

  /// Stable across edits, so the list keeps its place and its focus (`FE-11`).
  final int key;
  final LetterProposal proposal;
  final bool isTicked;

  ReviewItem ticked(bool value) =>
      ReviewItem(key: key, proposal: proposal, isTicked: value);

  ReviewItem withProposal(LetterProposal edited) =>
      ReviewItem(key: key, proposal: edited, isTicked: isTicked);

  @override
  bool operator ==(Object other) =>
      other is ReviewItem &&
      other.key == key &&
      other.proposal == proposal &&
      other.isTicked == isTicked;

  @override
  int get hashCode => Object.hash(key, proposal, isTicked);
}
