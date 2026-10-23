/// How many units a pack holds, when a shop says so plainly in one of
/// [texts] — "6 x 100g", "6 pack", "6's" — and only above one. Never guessed
/// past that. Both shops' parsers read it (`ENG-02`).
int? packCountIn(Iterable<String> texts) {
  for (final text in texts) {
    final match = _times.firstMatch(text) ?? _pack.firstMatch(text);
    final count = int.tryParse(match?.group(1) ?? '');
    if (count != null && count > 1) return count;
  }
  return null;
}

final _times = RegExp(r'(\d{1,3})\s*[x×]\s*\d', caseSensitive: false);
final _pack = RegExp(
  r'(\d{1,3})\s*(?:-\s*)?(?:pack|pk|\x27s)\b',
  caseSensitive: false,
);
