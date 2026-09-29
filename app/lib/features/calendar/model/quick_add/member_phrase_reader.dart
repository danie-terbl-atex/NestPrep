import 'quick_add_result.dart';
import 'quick_add_sentence.dart';

/// Reads who an event is for: `for Mia`, `for Mia and Sam`, `with Mia`, and
/// `Mia's`, matched without regard to case against the household's names and
/// first names. A name that is not a member stays in the title — "for school"
/// is part of what is happening (calendar ADR-0004).
final class MemberPhraseReader {
  MemberPhraseReader(this._sentence, List<QuickAddMember> members)
    : _names = [for (final member in members) ..._namesOf(member)]
        ..sort((a, b) => b.words.length.compareTo(a.words.length));

  final QuickAddSentence _sentence;

  /// Longest first, so "Mia Rose" wins over "Mia" when both are there.
  final List<_KnownName> _names;

  List<String> read() {
    final ids = <String>[];
    for (var i = 0; i < _sentence.length; i++) {
      if (!_sentence.isFree(i)) continue;
      final word = _sentence.word(i);
      if (word == 'for' || word == 'with') {
        _readNamesAfter(i, ids);
        continue;
      }
      final possessive = _possessiveAt(i);
      if (possessive != null) {
        _sentence.claim(
          i - possessive.words.length + 1,
          possessive.words.length,
        );
        if (!ids.contains(possessive.memberId)) ids.add(possessive.memberId);
      }
    }
    return ids;
  }

  /// "for Mia and Sam": names joined by "and" or "&" after the lead word. The
  /// lead word is only claimed when a name follows it.
  void _readNamesAfter(int leadIndex, List<String> ids) {
    var at = leadIndex + 1;
    var claimedAny = false;
    while (true) {
      final name = _nameAt(at);
      if (name == null) break;
      if (!ids.contains(name.memberId)) ids.add(name.memberId);
      _sentence.claim(at, name.words.length);
      claimedAny = true;
      at += name.words.length;
      final joiner = _sentence.word(at);
      if ((joiner == 'and' || joiner == '&') && _nameAt(at + 1) != null) {
        _sentence.claim(at, 1);
        at++;
      } else {
        break;
      }
    }
    if (claimedAny) _sentence.claim(leadIndex, 1);
  }

  _KnownName? _nameAt(int index) {
    for (final name in _names) {
      if (!_sentence.areFree(index, name.words.length)) continue;
      var matches = true;
      for (var j = 0; j < name.words.length; j++) {
        if (_sentence.word(index + j) != name.words[j]) {
          matches = false;
          break;
        }
      }
      if (matches) return name;
    }
    return null;
  }

  /// "Mia's dentist": the name ends at [index] with an apostrophe-s.
  _KnownName? _possessiveAt(int index) {
    final word = _sentence.word(index);
    if (word == null || !word.endsWith("'s")) return null;
    final bare = word.substring(0, word.length - 2);
    for (final name in _names) {
      final length = name.words.length;
      final start = index - length + 1;
      if (!_sentence.areFree(start, length)) continue;
      var matches = true;
      for (var j = 0; j < length - 1; j++) {
        if (_sentence.word(start + j) != name.words[j]) {
          matches = false;
          break;
        }
      }
      if (matches && name.words.last == bare) return name;
    }
    return null;
  }

  static Iterable<_KnownName> _namesOf(QuickAddMember member) {
    final words = member.name
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    return [
      _KnownName(member.id, words),
      if (words.length > 1) _KnownName(member.id, [words.first]),
    ];
  }
}

final class _KnownName {
  const _KnownName(this.memberId, this.words);

  final String memberId;
  final List<String> words;
}
