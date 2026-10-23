import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'fill_week_box.dart';

/// What a parent decided in *Fill the week*'s first step (lunch-box
/// ADR-0020), for `LunchAutoFill`: the household's [today] — no school day on
/// or before it is filled (ADR-0019's `hasHappened`) — and the [boxes] they
/// chose, in the order they chose them. No boxes means they skipped, and the
/// child's go-to boxes rotate as ADR-0003 says.
@immutable
final class LunchFillChoice {
  LunchFillChoice({required this.today, List<FillWeekBox> boxes = const []})
    : boxes = List.unmodifiable(boxes);

  final CalendarDate today;
  final List<FillWeekBox> boxes;

  bool get isSkipped => boxes.isEmpty;

  bool isOpen(CalendarDate day) => day.isAfter(today);
}
