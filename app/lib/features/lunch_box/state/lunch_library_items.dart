import '../data/lunch_repository.dart';
import '../model/lunch_board.dart';
import '../model/lunch_item.dart';

/// How something from outside the household — a shop product (lunch-box
/// ADR-0012 §3), a ready-made box's recipe or quick pick — becomes an item
/// in its lunch library before it goes in a box. One path, so every way in
/// reuses what the family already has the same way.
final class LunchLibraryItems {
  LunchLibraryItems({
    required LunchRepository lunchRepository,
    required this.householdId,
  }) : _lunches = lunchRepository;

  final LunchRepository _lunches;
  final String householdId;

  /// The library's item for [candidate], written first when the library
  /// lacks it.
  ///
  /// A candidate with a fixed id — `recipe-…`, `seed-…` — is that document:
  /// the household's own copy, put back out when it was put away, or else
  /// written at that id, so two phones write the same one. A candidate
  /// without an id is matched by name in its slot among the items in use,
  /// as typing a name again picks the household's own.
  Future<LunchItem> ensure(LunchItem candidate, LunchBoard board) async {
    if (candidate.id.isNotEmpty) return _ensureAt(candidate, board);
    if (board.itemLike(candidate) case final known?) return known;
    final id = await _lunches.addItem(householdId, candidate);
    return candidate.copyWith(id: id);
  }

  Future<LunchItem> _ensureAt(LunchItem candidate, LunchBoard board) async {
    final known = board.libraryById[candidate.id];
    if (known == null) {
      await _lunches.seedItems(householdId, [candidate]);
      return candidate;
    }
    if (!known.archived) return known;
    await _lunches.setItemArchived(
      householdId: householdId,
      itemId: known.id,
      archived: false,
    );
    return known.copyWith(archived: false);
  }
}
