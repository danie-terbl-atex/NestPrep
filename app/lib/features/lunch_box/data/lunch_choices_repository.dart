import '../model/lunch_choices.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_week.dart';

/// Kid picks as Firestore holds them (lunch-box ADR-0008): the options a
/// parent approved for a child's week, and the child's choice — which is
/// written into the plan itself. The rules refuse an unsafe option, and a
/// kid's choice that is not one of the approved options, as
/// `PermissionDeniedFailure`.
abstract interface class LunchChoicesRepository {
  /// One document per child for a week.
  static const choicesLimit = 20;

  /// Every child's options for [week] — what a parent's screen reads.
  Stream<List<LunchChoices>> watchWeek(String householdId, LunchWeek week);

  /// One child's options for [week], or none — the one document a kid's
  /// `own` grant opens.
  Stream<LunchChoices> watchChoices(
    String householdId, {
    required String childId,
    required LunchWeek week,
  });

  /// Sets the options of some of one school day's slots, by slot key; null
  /// takes a slot's options away. What the child had chosen there is
  /// forgotten. Every key must be [isoWeekday]'s — the rules refuse a write
  /// that reaches into another day.
  Future<void> setOptions({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required Map<String, List<LunchPick>?> options,
    required String by,
  });

  /// The child's choice: [pick] goes into that slot of their plan, and is
  /// recorded as theirs, in one batch.
  Future<void> choose({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required LunchSlot slot,
    required LunchPick pick,
  });
}
