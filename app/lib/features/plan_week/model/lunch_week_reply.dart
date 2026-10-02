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

/// What `buildLunchWeek` gave back (lunch-box ADR-0012): the week, already
/// checked on the server, and how many boxes the model reckons a pack does.
@immutable
final class LunchWeekReply {
  LunchWeekReply({
    required List<ReplyLunch> lunches,
    required Map<String, int> boxesPerPack,
    required this.budgetCents,
    required this.dropped,
    required this.callsLeft,
  }) : lunches = List.unmodifiable(lunches),
       boxesPerPack = Map.unmodifiable(boxesPerPack);

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
      );
    }
    throw const AiFailure(AiProblem.aiUnreadable);
  }

  final List<ReplyLunch> lunches;

  /// Product id → boxes one pack does.
  final Map<String, int> boxesPerPack;
  final int? budgetCents;

  /// Choices the server left out as not allowed.
  final int dropped;
  final int? callsLeft;
}
