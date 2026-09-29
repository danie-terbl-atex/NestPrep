import '../../../shared/copy/referral_copy.dart';
import '../../household/data/invite_sharer.dart';

/// A referral code leaves the app the way an invite does — the platform's
/// share sheet, through the invite sharer (`ENG-01`, household ADR-0003).
/// When `NESTPREP_INVITE_LINK` is configured the link carries the code as
/// `?referral=`, so a page can show it; the new family still types it
/// (subscriptions ADR-0002).
extension ShareReferralCode on InviteSharer {
  Future<InviteShareOutcome> shareReferralCode(String code) => share(
    subject: ReferralCopy.shareSubject,
    text: ReferralCopy.shareMessage(code: code, appLink: referralLink(code)),
  );

  Uri? referralLink(String code) {
    final link = appLink;
    if (link == null) return null;
    return link.replace(
      queryParameters: {...link.queryParameters, 'referral': code},
    );
  }
}
