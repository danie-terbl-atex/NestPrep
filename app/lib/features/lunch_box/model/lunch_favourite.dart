import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'lunch_box.dart';
import 'lunch_pick.dart';
import 'lunch_slot.dart';

part 'lunch_favourite.freezed.dart';
part 'lunch_favourite.g.dart';

/// A go-to box a parent locked for one child, at
/// `households/{id}/lunchFavourites/{favouriteId}` (lunch-box ADR-0003).
/// Auto-fill rotates a child's favourites through their weeks, so each one
/// comes round again rather than always landing on Monday.
///
/// It is not food in a box yet: safety is enforced when it is packed into a
/// plan, and the board flags a favourite that has stopped being safe.
@freezed
abstract class LunchFavourite with _$LunchFavourite {
  const factory LunchFavourite({
    @JsonKey(includeToJson: false) required String id,
    required String childId,
    required String name,

    /// Slot name → what goes in it.
    @Default(<String, LunchPick>{}) Map<String, LunchPick> picks,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _LunchFavourite;

  const LunchFavourite._();

  factory LunchFavourite.fromJson(Map<String, Object?> json) =>
      _$LunchFavouriteFromJson(json);

  factory LunchFavourite.of({
    required String id,
    required String childId,
    required String name,
    required LunchBox box,
    required String createdBy,
  }) => LunchFavourite(
    id: id,
    childId: childId,
    name: name.trim(),
    picks: {for (final (slot, pick) in box.filled) slot.name: pick},
    createdBy: createdBy,
  );

  static const nameLimit = 40;

  /// How many go-to boxes one child may keep — more than a term of variety.
  static const perChildLimit = 12;

  LunchBox get box =>
      LunchBox({for (final slot in LunchSlot.values) slot: picks[slot.name]});

  /// Oldest first, then by name, so the rotation order never shuffles.
  static int inRotationOrder(LunchFavourite a, LunchFavourite b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime != null && bTime != null && aTime != bTime) {
      return aTime.compareTo(bTime);
    }
    if (aTime == null && bTime != null) return 1;
    if (aTime != null && bTime == null) return -1;
    final byName = a.name.compareTo(b.name);
    return byName != 0 ? byName : a.id.compareTo(b.id);
  }
}
