/// Every word the about, privacy, terms, licences and consent screens say, and
/// the parental consent a child's profile asks for (`FE-19`, accounts
/// ADR-0005). Exported from `app_copy.dart`; a file of its own so it does
/// not fight the other features for the lines of one copy file.
abstract final class LegalCopy {
  static const privacyTitle = 'Privacy policy';
  static const termsTitle = 'Terms of service';
  static const aboutTitle = 'About NestPrep';
  static const licencesTitle = 'Licences';
  static const licencesSubtitle = 'The open-source software inside NestPrep';

  static String updated(String date) => 'Updated $date';
  static String version(int version) => 'Version $version';

  /// What a screen reader says for a gap in a draft document, so a listener
  /// knows it is not the finished words.
  static String placeholder(String text) => 'Still to be filled in: $text';
  static const linkWouldNotOpen =
      'That link would not open on this phone. Try again from a browser.';

  static const aboutTagline = 'One household, one app.';
  static const aboutBlurb =
      'NestPrep keeps a household\'s week in one place: school lunches '
      'planned per child, the family calendar, groceries, to-dos and chores, '
      'the papers you keep needing, and what a nanny or helper needs for a '
      'shift.';
  static String appVersion(String name, int build) =>
      'Version $name (build $build)';
  static const aboutSupport = 'Questions or problems';
  static const aboutSupportAddress = '[support email address]';
  static const aboutMadeIn = 'Made in South Africa';

  static const licencesEmptyTitle = 'No licences found';
  static const licencesEmptyBody =
      'This build lists no open-source licences, which is our mistake.';
  static String licenceCount(int count) =>
      count == 1 ? '1 licence' : '$count licences';

  static const consentTitle = 'Before you start';
  static const consentUpdatedTitle = 'We have updated our terms';
  static const consentIntro =
      'NestPrep holds information about you and the people you live with, '
      'including your children. Here is the short version of what we keep and '
      'why. The full documents are one tap away.';
  static const consentUpdatedIntro =
      'Our privacy policy or terms have changed since you last agreed. Have a '
      'look at what is new, then agree to carry on.';
  static const consentChildren = 'Your children';
  static const consentChildrenBody =
      'A child\'s profile — what they eat, their school, their lunches — is '
      'added by a parent, with that parent\'s consent. Children never sign up '
      'on their own.';
  static const consentHealth = 'Allergies and medication';
  static const consentHealthBody =
      'Health details help keep lunches and carers safe. Only the family, and '
      'people you choose, can see them.';
  static const consentDocuments = 'Papers and ID copies';
  static const consentDocumentsBody =
      'Documents you keep in a vault are yours; every opening is logged, and '
      'nobody else sees them unless you share them.';
  static const consentLocation = 'Location';
  static const consentLocationBody =
      'Only while you choose to share it, for as long as you say, and never '
      'in the background unless you turn that on.';
  static const consentRights =
      'You can download everything we hold about you, or delete your account, '
      'at any time from Account.';
  static const consentReadPrivacy = 'Read the privacy policy';
  static const consentReadTerms = 'Read the terms';
  static const consentAdult = 'I am 18 or older';
  static const consentAgree = 'I agree to the Terms and the Privacy Policy';
  static const consentAccept = 'Agree and continue';
  static const consentSignOut = 'Not now — sign out';

  static const guardianConsentLabel =
      'I am this child\'s parent or legal guardian, or I have their '
      'permission, and I agree to NestPrep keeping their information as the '
      'Privacy Policy describes.';
  static const guardianConsentNeeded =
      'A child\'s profile needs a parent\'s consent first.';
  static const guardianConsentTitle = 'A parent\'s consent';
  static const guardianConsentConfirm = 'I consent';
  static const guardianConsentCancel = 'Not now';
}
