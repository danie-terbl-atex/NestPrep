import '../../../shared/async/async_state.dart';
import '../../lunch_box/model/lunch_board.dart';

/// Child id → the name a person reads, from the board the phone holds — the
/// server answers in ids, never names (lunch-box ADR-0012 §2).
Map<String, String> childNamesOf(AsyncState<LunchBoard> board) =>
    switch (board) {
      AsyncData(:final value) => {
        for (final child in value.children)
          child.childId: child.child.member.displayName,
      },
      _ => const {},
    };
