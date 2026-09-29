/// The words quick add knows, lower-cased (calendar ADR-0004). One table per
/// idea, so a word a family uses that the grammar missed is a line here.
abstract final class QuickAddVocabulary {
  /// A single weekday names a day: "Friday" is the coming Friday.
  static const weekdays = <String, int>{
    'monday': 1,
    'mon': 1,
    'tuesday': 2,
    'tue': 2,
    'tues': 2,
    'wednesday': 3,
    'wed': 3,
    'weds': 3,
    'thursday': 4,
    'thu': 4,
    'thur': 4,
    'thurs': 4,
    'friday': 5,
    'fri': 5,
    'saturday': 6,
    'sat': 6,
    'sunday': 7,
    'sun': 7,
  };

  /// A plural weekday names a habit: "Tuesdays" is every Tuesday.
  static const pluralWeekdays = <String, int>{
    'mondays': 1,
    'tuesdays': 2,
    'wednesdays': 3,
    'thursdays': 4,
    'fridays': 5,
    'saturdays': 6,
    'sundays': 7,
  };

  static const months = <String, int>{
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  static const numbers = <String, int>{
    'one': 1,
    'a': 1,
    'an': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
  };

  /// "every second Thursday" — how many units apart.
  static const everyNth = <String, int>{
    'other': 2,
    'second': 2,
    '2nd': 2,
    'third': 3,
    '3rd': 3,
    'fourth': 4,
    '4th': 4,
  };

  /// Words that join the parts of a sentence and mean nothing on their own at
  /// the edge of a title: "Soccer at" is "Soccer".
  static const connectors = <String>{
    'at',
    'on',
    'from',
    'for',
    'with',
    'and',
    'the',
    'every',
    'each',
    'to',
    'until',
    'till',
    'til',
    'starting',
    'this',
    'next',
    '-',
    '–',
    '&',
  };

  /// A number, spelled or written: `3`, `three`.
  static int? count(String word) => int.tryParse(word) ?? numbers[word];
}
