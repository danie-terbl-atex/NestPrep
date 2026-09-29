import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'dinner_idea.dart';

/// One compartment the model filled: whose, which day, which slot, and the
/// library item — real ids, mapped back from its placeholders on the server.
@immutable
final class ReplyLunch {
  const ReplyLunch({
    required this.childId,
    required this.day,
    required this.slot,
    required this.itemId,
  });

  final String childId;

  /// ISO weekday, 1 (Monday) to 5 (Friday).
  final int day;
  final LunchSlot slot;
  final String itemId;

  static ReplyLunch? fromWire(Object? data) {
    if (data is! Map) return null;
    final childId = data['childId'];
    final day = data['day'];
    final slot = data['slot'];
    final itemId = data['itemId'];
    if (childId is! String || day is! int || slot is! String) return null;
    if (itemId is! String || day < 1 || day > 5) return null;
    final known = LunchSlot.fromName(slot);
    if (known == null) return null;
    return ReplyLunch(childId: childId, day: day, slot: known, itemId: itemId);
  }
}

/// One dinner the model planned: a meal from the library, or a new idea.
@immutable
final class ReplyDinner {
  const ReplyDinner({required this.day, this.mealId, this.idea});

  /// ISO weekday, 1 (Monday) to 7 (Sunday).
  final int day;
  final String? mealId;
  final DinnerIdea? idea;

  static ReplyDinner? fromWire(Object? data) {
    if (data is! Map) return null;
    final day = data['day'];
    final mealId = data['mealId'];
    if (day is! int || day < 1 || day > 7) return null;
    if (mealId is String) return ReplyDinner(day: day, mealId: mealId);
    final idea = DinnerIdea.fromWire(data['newMeal']);
    return idea == null ? null : ReplyDinner(day: day, idea: idea);
  }
}

/// What `planMyWeek` gave back (lunch-box ADR-0011): a proposal, already
/// checked on the server, that nothing has been written from.
@immutable
final class PlanWeekReply {
  const PlanWeekReply({
    required this.lunches,
    required this.dinners,
    required this.dinnersIncluded,
    required this.dropped,
    required this.callsLeft,
  });

  final List<ReplyLunch> lunches;
  final List<ReplyDinner> dinners;
  final bool dinnersIncluded;

  /// Choices the server left out as not allowed.
  final int dropped;

  /// AI plans left this month; null when nothing was asked of the model.
  final int? callsLeft;

  /// The callable's reply, parsed. A reply that is not the contract's shape is
  /// the model's answer arriving unreadable, and is said so — never cast
  /// (`ENG-09`). A single entry that does not parse is left out.
  factory PlanWeekReply.fromWire(Object? data) {
    if (data is! Map) throw const AiFailure(AiProblem.aiUnreadable);
    final lunches = data['lunches'];
    final dinners = data['dinners'];
    final included = data['dinnersIncluded'];
    final dropped = data['dropped'];
    final callsLeft = data['callsLeft'];
    if (lunches is! List || dinners is! List || included is! bool) {
      throw const AiFailure(AiProblem.aiUnreadable);
    }
    return PlanWeekReply(
      lunches: [for (final entry in lunches) ?ReplyLunch.fromWire(entry)],
      dinners: [for (final entry in dinners) ?ReplyDinner.fromWire(entry)],
      dinnersIncluded: included,
      dropped: dropped is int ? dropped : 0,
      callsLeft: callsLeft is int ? callsLeft : null,
    );
  }
}
