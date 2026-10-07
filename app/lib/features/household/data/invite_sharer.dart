import '../../../shared/copy/app_copy.dart';

/// How an invite leaves the app: the platform's own share sheet, so a parent
/// sends it the way they send everything else (household ADR-0003).
abstract interface class InviteSharer {
  /// Where somebody gets the app, for the shares that are not an invite.
  /// Null when no link is configured. An invite carries its own link
  /// (household ADR-0005).
  Uri? get appLink;

  Future<InviteShareOutcome> share({
    required String subject,
    required String text,
  });
}

enum InviteShareOutcome {
  /// The person picked somewhere to send it.
  shared,

  /// They closed the sheet. Not a failure; the code is still on screen.
  dismissed,

  /// There is no share sheet here, or it would not open. The screen offers
  /// the code to copy instead.
  unavailable,
}

/// The one way an invite is worded and sent, whichever screen sends it.
extension ShareInviteCode on InviteSharer {
  Future<InviteShareOutcome> shareCode({
    required String householdName,
    required String code,
  }) => share(
    subject: AccessCopy.inviteSubject(householdName),
    text: AccessCopy.inviteMessage(householdName: householdName, code: code),
  );
}
