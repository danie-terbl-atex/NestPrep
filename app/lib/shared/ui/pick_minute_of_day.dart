import 'package:flutter/material.dart';

/// Asks for a wall-clock time with the platform's own picker and answers in
/// minutes since midnight — the one representation the app stores a time of
/// day in (calendar ADR-0002, family-profiles ADR-0001). Null when the person
/// backs out.
///
/// Shared by the event sheet and the medication sheet (`ENG-02`), so the
/// conversion between the picker's hours and minutes and the stored number is
/// written once.
Future<int?> pickMinuteOfDay(
  BuildContext context, {
  required int initialMinutes,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: initialMinutes ~/ 60,
      minute: initialMinutes % 60,
    ),
  );
  if (picked == null) return null;
  return (picked.hour * 60) + picked.minute;
}
