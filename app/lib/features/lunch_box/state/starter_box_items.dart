import '../model/lunch_board.dart';
import '../model/lunch_item.dart';
import '../model/lunch_pick.dart';
import 'lunch_library_items.dart';

/// Ready-made boxes' picks made real before they are written (lunch-box
/// ADR-0020 §5): each pick whose item is a ready-made compartment's library
/// item (`StarterBoxItem`) is written to the library first — the household's
/// own copy reused, put back out if it was put away — and then carries every
/// code the library item and the box name, so the rules check the strictest
/// (ADR-0001). Every other pick is the household's already and passes as it
/// is.
final class StarterBoxItems {
  StarterBoxItems({required this._library});

  final LunchLibraryItems _library;

  /// [picks] (slot key → pick) with every one of [candidates] written first.
  Future<Map<String, LunchPick>> ensure(
    Map<String, LunchPick> picks, {
    required Map<String, LunchItem> candidates,
    required LunchBoard board,
  }) async {
    final byItem = <String, LunchPick>{};
    return {
      for (final MapEntry(:key, value: pick) in picks.entries)
        key: switch (candidates[pick.itemId]) {
          null => pick,
          final candidate => byItem[candidate.id] ??= await _pickOf(
            candidate,
            board,
          ),
        },
    };
  }

  Future<LunchPick> _pickOf(LunchItem candidate, LunchBoard board) async {
    final item = await _library.ensure(candidate, board);
    return LunchPick(
      itemId: item.id,
      name: item.name,
      allergens: {...item.allergens, ...candidate.allergens}.toList(),
    );
  }
}
