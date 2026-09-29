import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import 'lunch_board.dart';
import 'lunch_box.dart';
import 'lunch_card_naming.dart';
import 'lunch_card_options.dart';
import 'lunch_pick.dart';
import 'lunch_week.dart';

/// Everything a shared lunch card shows, and nothing else (lunch-box
/// ADR-0005). This is the one place that decides what leaves the phone: it
/// reads a child's week and, by the parent's choice, their initials or first
/// name — never their food rules, school, allergies or what came home.
@immutable
class LunchCardContent {
  LunchCardContent({
    required this.week,
    required List<LunchCardChild> children,
    required this.isFamily,
    this.hiddenChildCount = 0,
  }) : children = List.unmodifiable(children);

  /// The card for [options] from the board the lunch screen already holds.
  /// A family card draws the first [limit] children — [maxChildren] on a
  /// card, all of them on the planner's pages — and counts the rest.
  factory LunchCardContent.from(
    LunchBoard board,
    LunchCardOptions options, {
    int limit = maxChildren,
  }) {
    final chosen = options.isFamily
        ? board.children
        : [board.childWeek(options.childId ?? '') ?? board.children.firstOrNull]
              .nonNulls
              .toList();
    final drawn = chosen.take(limit).toList();
    return LunchCardContent(
      week: board.week,
      isFamily: options.isFamily,
      hiddenChildCount: chosen.length - drawn.length,
      children: [
        for (final (index, childWeek) in drawn.indexed)
          LunchCardChild(
            number: index + 1,
            label: _labelFor(childWeek.child.member, options.naming),
            isFirstName: options.naming == LunchCardNaming.firstNames,
            color: childWeek.child.member.color,
            days: [
              for (final day in childWeek.days)
                LunchCardDay(
                  date: day.date,
                  box: _withoutAllergens(day.box, board),
                ),
            ],
          ),
      ],
    );
  }

  /// Four columns are what stays legible 1080 pixels wide.
  static const maxChildren = 4;

  final LunchWeek week;
  final List<LunchCardChild> children;

  /// Every child's week on one card, rather than one child's.
  final bool isFamily;

  /// Children past [maxChildren], said as "and N more".
  final int hiddenChildCount;

  /// Nothing packed on any day for anybody: there is nothing to share yet.
  bool get isEmpty => children.every((child) => child.isEmpty);

  /// Each thing in the week's boxes once, in the order the week packs them.
  List<String> get itemNames {
    final seen = <String>{};
    return [
      for (final child in children)
        for (final day in child.days)
          for (final name in day.itemNames)
            if (seen.add(name)) name,
    ];
  }

  static String? _labelFor(Member member, LunchCardNaming naming) =>
      switch (naming) {
        LunchCardNaming.none => null,
        LunchCardNaming.initials => member.initials,
        LunchCardNaming.firstNames => _firstName(member.displayName),
      };

  static String _firstName(String displayName) {
    final words = displayName.trim().split(RegExp(r'\s+'));
    return words.first.isEmpty ? displayName : words.first;
  }

  /// The box as the card draws it: each compartment's item under the name
  /// the library gives it now, and no allergen codes at all — the card never
  /// needs them, so it never holds them.
  static LunchBox _withoutAllergens(LunchBox box, LunchBoard board) =>
      LunchBox({
        for (final (slot, pick) in box.filled)
          slot: LunchPick(
            itemId: pick.itemId,
            name: board.libraryById[pick.itemId]?.name ?? pick.name,
          ),
      });
}

/// One child's week on a card: a number, the label the parent chose (or
/// none), and five days.
@immutable
class LunchCardChild {
  LunchCardChild({
    required this.number,
    required this.label,
    required this.color,
    required List<LunchCardDay> days,
    this.isFirstName = false,
  }) : days = List.unmodifiable(days);

  /// 1-based, for a family card with no names.
  final int number;

  /// Initials or a first name; null when the parent chose no names.
  final String? label;

  /// [label] is a first name the parent opted into, rather than initials.
  final bool isFirstName;
  final MemberColor color;
  final List<LunchCardDay> days;

  bool get isEmpty => days.every((day) => day.box.isEmpty);
}

/// One school day's box on a card.
@immutable
class LunchCardDay {
  const LunchCardDay({required this.date, required this.box});

  final CalendarDate date;
  final LunchBox box;

  /// What is in the box, main first.
  List<String> get itemNames => [for (final (_, pick) in box.filled) pick.name];
}
