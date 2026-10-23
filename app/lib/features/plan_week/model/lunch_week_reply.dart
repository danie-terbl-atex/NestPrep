import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../lunch_box/model/lunch_slot.dart';

/// One compartment the model filled with a shop's product: whose, which day,
/// which slot, for which idea — real ids, mapped back on the server.
@immutable
final class ReplyLunch {
  const ReplyLunch({
    required this.childId,
    required this.day,
    required this.slot,
    required this.ideaId,
    required this.productId,
  });

  final String childId;

  /// ISO weekday, 1 (Monday) to 5 (Friday).
  final int day;
  final LunchSlot slot;
  final String ideaId;
  final String productId;

  static ReplyLunch? fromWire(Object? data) {
    if (data
        case {
          'childId': final String childId,
          'day': final int day,
          'slot': final String slotName,
          'ideaId': final String ideaId,
          'productId': final String productId,
        }
        when day >= 1 && day <= 5) {
      final slot = LunchSlot.fromName(slotName);
      if (slot == null) return null;
      return ReplyLunch(
        childId: childId,
        day: day,
        slot: slot,
        ideaId: ideaId,
        productId: productId,
      );
    }
    return null;
  }
}

/// One ingredient of a dish and the store product the week buys it as
/// (lunch-box ADR-0021 §4).
typedef ReplyDishPart = ({String ingredient, String productId});

/// What `buildLunchWeek` gave back (lunch-box ADR-0012): the week, already
/// checked on the server, how many boxes the model reckons a pack does, and
/// — for a dish — the products it is bought as (ADR-0021).
@immutable
final class LunchWeekReply {
  LunchWeekReply({
    required List<ReplyLunch> lunches,
    required Map<String, int> boxesPerPack,
    required this.budgetCents,
    required this.dropped,
    required this.callsLeft,
    Map<String, List<ReplyDishPart>> dishes = const {},
  }) : lunches = List.unmodifiable(lunches),
       boxesPerPack = Map.unmodifiable(boxesPerPack),
       dishes = Map.unmodifiable(dishes);

  /// The callable's reply, parsed; the wrong shape is an unreadable answer,
  /// and a single entry that does not parse is left out (`ENG-09`).
  factory LunchWeekReply.fromWire(Object? data) {
    if (data case {
      'lunches': final List<Object?> lunches,
      'packs': final List<Object?> packs,
    }) {
      return LunchWeekReply(
        lunches: [for (final entry in lunches) ?ReplyLunch.fromWire(entry)],
        boxesPerPack: {
          for (final entry in packs)
            if (entry
                case {
                  'productId': final String productId,
                  'boxesPerPack': final int boxes,
                }
                when boxes >= 1 && boxes <= 100)
              productId: boxes,
        },
        budgetCents: switch (data['budgetCents']) {
          final int cents when cents > 0 => cents,
          _ => null,
        },
        dropped: switch (data['dropped']) {
          final int dropped => dropped,
          _ => 0,
        },
        callsLeft: switch (data['callsLeft']) {
          final int calls => calls,
          _ => null,
        },
        dishes: _dishes(data['dishes']),
      );
    }
    throw const AiFailure(AiProblem.aiUnreadable);
  }

  /// Absent from a server before dishes; an entry that does not parse is
  /// left out, and its dish then buys nothing.
  static Map<String, List<ReplyDishPart>> _dishes(Object? data) => {
    if (data is List<Object?>)
      for (final entry in data)
        if (entry case {
          'ideaId': final String ideaId,
          'parts': final List<Object?> parts,
        })
          ideaId: [
            for (final part in parts)
              if (part case {
                'ingredient': final String ingredient,
                'productId': final String productId,
              })
                (ingredient: ingredient, productId: productId),
          ],
  };

  final List<ReplyLunch> lunches;

  /// Product id → boxes one pack does — a dish's ingredient products too.
  final Map<String, int> boxesPerPack;

  /// Idea id → the products a dish is bought as.
  final Map<String, List<ReplyDishPart>> dishes;
  final int? budgetCents;

  /// Choices the server left out as not allowed.
  final int dropped;
  final int? callsLeft;
}
