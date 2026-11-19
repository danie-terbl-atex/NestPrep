import '../../../shared/copy/app_copy.dart';

/// Where somebody is on their way in (onboarding ADR-0001): which step, of how
/// many, named in words for the bar and a screen reader.
abstract interface class OnboardingStep {
  int get index;
  int get count;
  String get what;
}

extension OnboardingStepLabel on OnboardingStep {
  String get label => AppCopy.onboardingStep(index + 1, count, what);
}

/// The way in for somebody starting a household. The account is the first
/// segment, so the bar already shows progress on the promises.
enum CreatorStep implements OnboardingStep {
  account(AppCopy.stepAccount),
  promises(AppCopy.stepPromises),
  household(AppCopy.stepHousehold),
  family(AppCopy.stepFamily),
  calendar(AppCopy.stepCalendar);

  const CreatorStep(this.what);

  @override
  final String what;

  @override
  int get count => values.length;
}

/// The way in for somebody holding an invite (household ADR-0011).
enum InviteeStep implements OnboardingStep {
  account(AppCopy.stepAccount),
  promises(AppCopy.stepPromises),
  join(AppCopy.stepJoin);

  const InviteeStep(this.what);

  @override
  final String what;

  @override
  int get count => values.length;
}
