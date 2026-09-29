import 'quick_add_vocabulary.dart';

/// One line of quick add, split into words, with a note of which words a
/// phrase has already claimed (calendar ADR-0004).
///
/// Each phrase reader walks the words, claims the ones it understood, and
/// leaves the rest. What nobody claimed is the title — which is why the order
/// the readers run in matters, and why it lives in one place, the parser.
final class QuickAddSentence {
  QuickAddSentence(String text) {
    for (final piece in text.split(_separators)) {
      if (piece.isEmpty) continue;
      final word = _normalise(piece);
      if (word.isEmpty) continue;
      _raw.add(piece);
      _words.add(word);
    }
    _used = List.filled(_words.length, false);
  }

  /// Whitespace and commas split words; "Mon,Wed" is two of them.
  static final _separators = RegExp(r'[\s,]+');

  final _raw = <String>[];
  final _words = <String>[];
  late final List<bool> _used;

  int get length => _words.length;

  /// The word at [index], lower-cased and without the punctuation around it,
  /// or null past either end — so a reader can look ahead without counting.
  String? word(int index) =>
      index >= 0 && index < _words.length ? _words[index] : null;

  bool isFree(int index) =>
      index >= 0 && index < _words.length && !_used[index];

  /// Whether every word from [start] for [count] words is still unclaimed.
  bool areFree(int start, int count) {
    for (var i = start; i < start + count; i++) {
      if (!isFree(i)) return false;
    }
    return true;
  }

  void claim(int start, int count) {
    for (var i = start; i < start + count; i++) {
      if (i >= 0 && i < _used.length) _used[i] = true;
    }
  }

  /// Claims the connecting word just before [index] — the "at" of "at 5", the
  /// "on" of "on Friday" — when it is one of [words] and nobody has it yet.
  void claimLeading(int index, Set<String> words) {
    final before = index - 1;
    if (isFree(before) && words.contains(word(before))) claim(before, 1);
  }

  /// What nobody claimed, as the member typed it, with connecting words at
  /// either edge dropped and the first letter capitalised.
  String get leftover {
    final kept = <String>[
      for (var i = 0; i < _words.length; i++)
        if (!_used[i]) _raw[i],
    ];
    while (kept.isNotEmpty && _isConnector(kept.first)) {
      kept.removeAt(0);
    }
    while (kept.isNotEmpty && _isConnector(kept.last)) {
      kept.removeLast();
    }
    final title = kept.join(' ').trim();
    if (title.isEmpty) return '';
    return title[0].toUpperCase() + title.substring(1);
  }

  static bool _isConnector(String raw) =>
      QuickAddVocabulary.connectors.contains(_normalise(raw));

  /// Lower case, without the quotes and brackets around a word or the full stop
  /// after it — `a.m.` is read as `am` before that stop goes.
  static String _normalise(String raw) {
    var word = raw.toLowerCase().replaceAll('’', "'");
    word = word.replaceAll(RegExp(r'''^[("'\[“‘]+'''), '');
    word = word.replaceAll(RegExp(r'''[)"'\]”;:!?]+$'''), '');
    if (word == 'a.m.' || word == 'a.m') return 'am';
    if (word == 'p.m.' || word == 'p.m') return 'pm';
    if (word.endsWith('.')) word = word.substring(0, word.length - 1);
    if (word == '@') return 'at';
    return word;
  }
}
