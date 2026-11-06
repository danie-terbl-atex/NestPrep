import 'chore_picture.dart';
import 'chore_picture_catalogue.dart';

/// The pictures that fit a task's title, best first — what the task sheet
/// offers, never sets (todos ADR-0005). A keyword the title contains as a
/// whole phrase outranks one word in common, and plurals and "-ing" forms
/// count as the word: "Wash the dishes" finds "wash dish".
List<ChorePicture> suggestChorePictures(
  String title, {
  required int limit,
  List<ChorePicture> catalogue = chorePictureCatalogue,
}) {
  final words = _words(title);
  if (words.isEmpty) return const [];
  final scored = [
    for (final (index, picture) in catalogue.indexed)
      if (_score(picture, words) case final score when score > 0)
        (picture: picture, score: score, index: index),
  ];
  scored.sort(
    (a, b) => b.score != a.score
        ? b.score.compareTo(a.score)
        : a.index.compareTo(b.index),
  );
  return [for (final entry in scored.take(limit)) entry.picture];
}

/// The pictures a search in the picker finds: every word typed starts a word
/// of the picture's label or keywords, so "bru" finds *Brush teeth* as it is
/// typed. An empty search finds everything, in catalogue order.
List<ChorePicture> searchChorePictures(
  String query, {
  List<ChorePicture> catalogue = chorePictureCatalogue,
}) {
  final typed = _normalise(query).split(' ').where((w) => w.isNotEmpty);
  if (typed.isEmpty) return catalogue;
  final found = [
    for (final picture in catalogue)
      if (typed.every(
        (word) => _searchWords(picture).any(
          (candidate) =>
              candidate.startsWith(word) || _stem(candidate) == _stem(word),
        ),
      ))
        picture,
  ];
  final ranked = suggestChorePictures(
    query,
    limit: found.length,
    catalogue: found,
  );
  return [...ranked, ...found.where((picture) => !ranked.contains(picture))];
}

const _phraseScore = 10;
const _keywordScore = 4;
const _wordScore = 1;

int _score(ChorePicture picture, List<String> title) {
  var score = 0;
  final shared = <String>{};
  for (final phrase in [picture.label, ...picture.keywords]) {
    final words = _words(phrase);
    if (words.isEmpty) continue;
    if (_contains(title, words)) {
      score += words.length > 1 ? _phraseScore + words.length : _keywordScore;
    }
    shared.addAll(
      words.where((word) => !_weakStems.contains(word) && title.contains(word)),
    );
  }
  return score + shared.length * _wordScore;
}

bool _contains(List<String> haystack, List<String> needle) {
  for (var start = 0; start + needle.length <= haystack.length; start++) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset++) {
      if (haystack[start + offset] != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

final _searchWordsCache = Expando<List<String>>();

List<String> _searchWords(ChorePicture picture) =>
    _searchWordsCache[picture] ??= {
      for (final phrase in [picture.label, ...picture.keywords])
        ..._normalise(phrase).split(' ').where((w) => w.isNotEmpty),
    }.toList();

List<String> _words(String text) => [
  for (final word in _normalise(text).split(' '))
    if (word.isNotEmpty && !_ignored.contains(word)) _stem(word),
];

String _normalise(String text) => text
    .toLowerCase()
    .replaceAll('’', '')
    .replaceAll("'", '')
    .replaceAll(RegExp('[^a-z0-9]+'), ' ')
    .trim();

/// A light stemmer: the same root for "dish", "dishes"; "tidy", "tidies",
/// "tidying"; "make", "making"; "cookie", "cookies". Both sides go through it, so it only has to be
/// consistent, not correct English.
String _stem(String word) {
  var stem = word;
  if (stem.length > 4 && stem.endsWith('ies')) {
    stem = '${stem.substring(0, stem.length - 3)}y';
  } else if (stem.length > 4 &&
      stem.endsWith('es') &&
      RegExp('(s|x|z|ch|sh)es\$').hasMatch(stem)) {
    stem = stem.substring(0, stem.length - 2);
  } else if (stem.length > 3 && stem.endsWith('s') && !stem.endsWith('ss')) {
    stem = stem.substring(0, stem.length - 1);
  }
  if (stem.length > 5 && stem.endsWith('ing')) {
    stem = stem.substring(0, stem.length - 3);
    final last = stem.length - 1;
    if (stem.length > 2 && stem[last] == stem[last - 1] && stem[last] != 's') {
      stem = stem.substring(0, last);
    }
  }
  if (stem.length > 3 && stem.endsWith('e') && !stem.endsWith('ee')) {
    stem = stem.substring(0, stem.length - 1);
  }
  if (stem.length > 2 && stem.endsWith('y')) {
    stem = '${stem.substring(0, stem.length - 1)}i';
  }
  return stem;
}

const _ignored = {
  'a',
  'an',
  'the',
  'your',
  'my',
  'his',
  'her',
  'their',
  'our',
  'to',
  'and',
  'of',
  'for',
  'in',
  'on',
  'at',
  'with',
  'all',
  'please',
};

/// Words that belong in a phrase but say nothing on their own.
const _weak = {
  'up',
  'out',
  'off',
  'away',
  'down',
  'do',
  'get',
  'go',
  'put',
  'some',
  'take',
  'make',
  'have',
};

final _weakStems = {for (final word in _weak) _stem(word)};
