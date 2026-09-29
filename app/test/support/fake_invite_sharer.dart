import 'package:nestprep/features/household/data/invite_sharer.dart';

/// The share sheet, without a platform: it records what would have been sent
/// and answers with whatever the test says the person did.
final class FakeInviteSharer implements InviteSharer {
  FakeInviteSharer({this.appLink});

  @override
  final Uri? appLink;

  /// What the next share answers with.
  InviteShareOutcome outcome = InviteShareOutcome.shared;

  final sent = <({String subject, String text})>[];

  @override
  Future<InviteShareOutcome> share({
    required String subject,
    required String text,
  }) async {
    sent.add((subject: subject, text: text));
    return outcome;
  }
}
