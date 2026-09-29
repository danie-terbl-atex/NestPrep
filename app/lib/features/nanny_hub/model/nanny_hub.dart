import 'package:flutter/foundation.dart';

import 'child_card.dart';
import 'emergency_contact.dart';
import 'guide_spot.dart';
import 'home_sheet.dart';
import 'house_rule.dart';
import 'shift.dart';
import 'shift_checklist.dart';
import 'shift_moment.dart';
import 'shift_summary.dart';

/// Everything the hub holds, as the listeners last saw it — the one value the
/// hub's screens render, so they share one loading state (foundation
/// ADR-0006). Nothing here is kept that a listener does not also carry.
@immutable
class NannyHub {
  NannyHub({
    required List<ChildCard> cards,
    required List<EmergencyContact> contacts,
    required this.sheet,
    required List<GuideSpot> guide,
    required List<HouseRule> rules,
    required List<ShiftChecklist> checklists,
    required List<Shift> openShifts,
    required List<ShiftSummary> summaries,
  }) : cardsById = Map.unmodifiable({for (final card in cards) card.id: card}),
       contacts = List.unmodifiable(
         <EmergencyContact>[...contacts]..sort(EmergencyContact.bySheetOrder),
       ),
       guide = List.unmodifiable(guide),
       rules = List.unmodifiable(rules),
       _checklists = Map.unmodifiable({
         for (final checklist in checklists)
           ?checklist.moment: checklist,
       }),
       openShifts = List.unmodifiable(openShifts),
       summaries = List.unmodifiable(
         <ShiftSummary>[...summaries]..sort(
           (a, b) => (b.endedAt ?? _pending).compareTo(a.endedAt ?? _pending),
         ),
       );

  /// A summary whose end is still being written sorts first: it is the newest.
  static final _pending = DateTime.utc(9999);

  final Map<String, ChildCard> cardsById;

  /// Parents first, the hospital last.
  final List<EmergencyContact> contacts;
  final HomeSheet sheet;

  /// In the order they were added, which is the order a parent walked the
  /// house in.
  final List<GuideSpot> guide;
  final List<HouseRule> rules;
  final Map<ShiftMoment, ShiftChecklist> _checklists;
  final List<Shift> openShifts;

  /// Newest first.
  final List<ShiftSummary> summaries;

  ChildCard cardFor(String memberId) =>
      cardsById[memberId] ?? ChildCard.empty(memberId);

  ShiftChecklist checklistFor(ShiftMoment moment) =>
      _checklists[moment] ?? ShiftChecklist.empty(moment);

  /// Every checklist in the order a shift meets them.
  List<ShiftChecklist> get checklists => [
    for (final moment in ShiftMoment.values) checklistFor(moment),
  ];

  int get checklistItemCount =>
      checklists.fold(0, (count, list) => count + list.items.length);

  /// The shift this member is on right now, if any.
  Shift? openShiftOf(String? memberId) => memberId == null
      ? null
      : openShifts.where((shift) => shift.carerMemberId == memberId).firstOrNull;

  ShiftSummary? get latestSummary => summaries.firstOrNull;

  ShiftSummary? summaryOf(String shiftId) =>
      summaries.where((summary) => summary.shiftId == shiftId).firstOrNull;
}
