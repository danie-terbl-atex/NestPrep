import '../../features/feedback/model/feedback_draft.dart';

abstract final class FeedbackCopy {
  static const entry = 'Send feedback';
  static const entryHint = 'Tell us what works and what doesn’t';
  static const title = 'Send feedback';
  static const subtitle = 'Straight to the people who make NestPrep';
  static const lead =
      'Something broken, something you love, or something you wish it did? '
      'Every message is read.';

  static const kindQuestion = 'What is it about?';
  static String kind(FeedbackKind kind) => switch (kind) {
    FeedbackKind.problem => 'Something isn’t working',
    FeedbackKind.praise => 'Something I like',
    FeedbackKind.idea => 'An idea or wish',
  };

  static const areaQuestion = 'Which part of the app? (optional)';
  static String area(FeedbackArea area) => switch (area) {
    FeedbackArea.today => 'Today',
    FeedbackArea.calendar => 'Calendar',
    FeedbackArea.lunch => 'Lunches',
    FeedbackArea.meals => 'Meals and recipes',
    FeedbackArea.groceries => 'Groceries',
    FeedbackArea.todos => 'To-dos and chores',
    FeedbackArea.documents => 'Documents',
    FeedbackArea.care => 'Nanny and home care',
    FeedbackArea.family => 'Family and household',
    FeedbackArea.account => 'Account and sign-in',
  };

  static const messageLabel = 'Your message';
  static String messageHint(FeedbackKind? kind) => switch (kind) {
    FeedbackKind.problem => 'What happened, and what did you expect to happen?',
    FeedbackKind.praise => 'What do you like about it?',
    FeedbackKind.idea => 'What would make NestPrep better for you?',
    null => 'Tell us in your own words',
  };
  static const privacyNote =
      'Please leave out anything private, like a child’s health details. '
      'We keep your message with your account, and it is deleted if you '
      'delete your account.';
  static const mayContact = 'You may email me about this';
  static const send = 'Send feedback';

  static const deliveredTitle = 'Thank you';
  static const deliveredBody =
      'We have your feedback. It helps us decide what to fix and build next.';
  static const queuedBody =
      'You seem to be offline. Your feedback is saved on this phone and will '
      'be sent as soon as you are back online.';
  static const another = 'Send something else';
  static const done = 'Done';
}
