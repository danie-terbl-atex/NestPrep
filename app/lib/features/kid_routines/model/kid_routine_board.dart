import 'package:flutter/foundation.dart';

import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import 'kid_routine.dart';
import 'kid_routine_slot.dart';

/// The household's kid routines beside its children, as the parent's screen
/// reads them (kid-routines ADR-0001). Grouped once per emission (`FE-12`).
@immutable
final class KidRoutineBoard {
  KidRoutineBoard({
    required List<KidRoutine> routines,
    required List<Member> members,
  }) : kids = [
         for (final member in members)
           if (member.role == MemberRole.kid) member,
       ],
       _byKidAndSlot = _group(routines);

  final List<Member> kids;
  final Map<(String, KidRoutineSlot), List<KidRoutine>> _byKidAndSlot;

  /// A shared routine is under every child it names.
  List<KidRoutine> routinesFor(String kidId, KidRoutineSlot slot) =>
      _byKidAndSlot[(kidId, slot)] ?? const [];

  static Map<(String, KidRoutineSlot), List<KidRoutine>> _group(
    List<KidRoutine> routines,
  ) {
    final sorted = [...routines]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final grouped = <(String, KidRoutineSlot), List<KidRoutine>>{};
    for (final routine in sorted) {
      for (final kidId in routine.kidIds) {
        grouped.putIfAbsent((kidId, routine.slot), () => []).add(routine);
      }
    }
    return grouped;
  }
}
