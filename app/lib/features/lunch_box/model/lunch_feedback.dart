import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'lunch_slot.dart';

part 'lunch_feedback.freezed.dart';
part 'lunch_feedback.g.dart';

/// Whether a box, or one thing in it, came home eaten.
enum LunchVerdict {
  ate,
  left;

  static LunchVerdict? fromName(String name) =>
      values.where((verdict) => verdict.name == name).firstOrNull;
}

/// What came home from one day's box (lunch-box ADR-0003): a thumbs up or
/// down for the box, and optionally for the things in it. Future suggestions
/// read it; nothing else does.
@freezed
abstract class LunchFeedback with _$LunchFeedback {
  const factory LunchFeedback({
    /// `LunchVerdict.name`, as stored.
    required String verdict,

    /// Slot name → `LunchVerdict.name`, for the things somebody marked one by
    /// one. A slot not here was judged with the box.
    @Default(<String, String>{}) Map<String, String> items,

    /// The member who marked it.
    required String by,
    @ServerTimestampConverter() DateTime? at,
  }) = _LunchFeedback;

  const LunchFeedback._();

  factory LunchFeedback.fromJson(Map<String, Object?> json) =>
      _$LunchFeedbackFromJson(json);

  factory LunchFeedback.of({
    required LunchVerdict box,
    required Map<LunchSlot, LunchVerdict> items,
    required String by,
  }) => LunchFeedback(
    verdict: box.name,
    items: {
      for (final MapEntry(:key, :value) in items.entries) key.name: value.name,
    },
    by: by,
  );

  /// The box's verdict; an unknown stored word reads as no verdict at all.
  LunchVerdict? get boxVerdict => LunchVerdict.fromName(verdict);

  /// What one slot's item was judged: its own mark, else the box's.
  LunchVerdict? verdictFor(LunchSlot slot) {
    final own = items[slot.name];
    return own == null ? boxVerdict : LunchVerdict.fromName(own);
  }

  /// Whether [slot] was marked on its own rather than with the box.
  bool isMarkedOnItsOwn(LunchSlot slot) => items.containsKey(slot.name);
}
