/// The rules for a document's tags, on the phone (documents ADR-0005).
///
/// **The limits are enforced in `firestore.rules`**, which refuses a ninth tag
/// or one past 24 characters; this copy exists so the field stops somebody
/// before the write does (`FE-04`, `FE-10`).
abstract final class DocumentTags {
  static const maxTags = 8;
  static const maxLength = 24;

  /// A tag as typed, tidied: spaces collapsed and trimmed. Empty means none.
  static String tidy(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Whether [tag] is already in [tags], ignoring case — "ID" and "id" are one
  /// tag to a person searching.
  static bool contains(List<String> tags, String tag) {
    final key = tag.toLowerCase();
    return tags.any((existing) => existing.toLowerCase() == key);
  }

  /// [tags] with [raw] added, or unchanged when it is empty, too long, a
  /// repeat, or one too many. The field says which, so nothing is dropped
  /// silently (`FE-10`).
  static List<String> adding(List<String> tags, String raw) {
    final tag = tidy(raw);
    if (!canAdd(tags, tag)) return tags;
    return [...tags, tag];
  }

  static bool canAdd(List<String> tags, String tag) =>
      tag.isNotEmpty &&
      tag.length <= maxLength &&
      tags.length < maxTags &&
      !contains(tags, tag);

  /// Every tag used across [lists], once each, in the order first seen — the
  /// search screen's tag filters and the field's suggestions.
  static List<String> vocabulary(Iterable<List<String>> lists) {
    final seen = <String>[];
    for (final tags in lists) {
      for (final tag in tags) {
        if (!contains(seen, tag)) seen.add(tag);
      }
    }
    return seen;
  }
}
