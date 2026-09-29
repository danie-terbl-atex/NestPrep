import '../../features/lunch_box/model/lunch_card_format.dart';
import '../../features/lunch_box/model/lunch_card_naming.dart';
import '../../features/lunch_box/model/lunch_card_style.dart';

/// Every word the shareable lunch card, its screen and the printable planner
/// say (`FE-19`, lunch-box ADR-0005), beside `LunchCopy` rather than in it so
/// the launch feature's file stays readable.
abstract final class LunchShareCopy {
  // The way in, on the lunch board.
  static const openShare = 'Share';

  // The screen.
  static const title = 'Share the week';
  static String previewLabel(String items) => items.isEmpty
      ? 'A lunch card for this week, with nothing packed yet'
      : 'A lunch card for this week: $items';
  static const whose = 'Whose lunches';
  static const everyone = 'Everyone';
  static const shape = 'Shape';
  static String formatName(LunchCardFormat format) => switch (format) {
    LunchCardFormat.story => 'Story',
    LunchCardFormat.post => 'Post',
    LunchCardFormat.chat => 'WhatsApp',
  };
  static String formatHint(LunchCardFormat format) => switch (format) {
    LunchCardFormat.story => 'Tall, for Instagram and TikTok stories',
    LunchCardFormat.post => 'Square, for a feed post',
    LunchCardFormat.chat => 'Big in a chat, and a portrait post',
  };
  static const look = 'Look';
  static String styleName(LunchCardStyle style) => switch (style) {
    LunchCardStyle.cream => 'Cream',
    LunchCardStyle.leaf => 'Leaf',
    LunchCardStyle.straw => 'Straw',
    LunchCardStyle.forest => 'Forest',
  };
  static const names = 'Names on the card';
  static String namingName(LunchCardNaming naming) => switch (naming) {
    LunchCardNaming.none => 'No names',
    LunchCardNaming.initials => 'Initials',
    LunchCardNaming.firstNames => 'First names',
  };
  static const privacyTitle = 'Never on a card: allergies, schools, surnames';
  static const privacyNote =
      'A first name goes on only when you choose it — each time you share.';
  static const invite = 'Add “Plan yours free”';
  static const inviteHint = 'A quiet line so friends can find the app';
  static const shareImage = 'Share image';
  static const nothingToShare =
      'Nothing is packed this week yet. Pack a box first — or print a blank '
      'planner below.';
  static const onlyPlanners =
      'Only the people who plan the lunches can share them. Ask a parent.';

  // The card.
  static const headline = 'Lunches this week';
  static String packedFor(String label) => 'Packed for $label';
  static const nothingPacked = 'Nothing packed';

  /// Items in a row, never breaking a line before a separator.
  static String itemList(Iterable<String> names) => names.join('\u00A0· ');
  static const inTheBoxes = 'In the boxes';
  static String andMore(int count) =>
      count == 1 ? 'and 1 more child' : 'and $count more children';
  static const plannedWith = 'Planned with';
  static const plannedWithNestPrep = 'Planned with Nest Prep';
  static const planYours = 'Plan yours free';
  static const findTheApp = 'Nest Prep, in your app store';

  // What goes with the image.
  static const shareSubject = 'Our lunches this week';
  static String shareText(String? link) => link == null
      ? 'Our school lunches this week, planned with Nest Prep.'
      : 'Our school lunches this week, planned with Nest Prep: $link';
  static String cardFileName(String week, LunchCardFormat format) =>
      'nest-prep-lunches-$week-${format.name}.png';

  // The printable planner.
  static const plannerSection = 'Printable planner';
  static const plannerHint =
      'A4, for the fridge or the family group. The blank one is free to pass '
      'on.';
  static const plannerFilled = 'This week';
  static const plannerBlank = 'Blank';
  static const print = 'Print';
  static const sendPdf = 'Send PDF';
  static const plannerTitle = 'Lunch box planner';
  static const plannerWeekBlank = 'Week of';
  static const plannerForBlank = 'For';
  static const plannerPrep = 'Sunday prep';
  static const plannerShopping = 'To buy';
  static String plannerFileName(String? week) => week == null
      ? 'nest-prep-lunch-planner.pdf'
      : 'nest-prep-lunch-planner-$week.pdf';
  static const plannerShareText = 'A weekly lunch box planner from Nest Prep.';
}
