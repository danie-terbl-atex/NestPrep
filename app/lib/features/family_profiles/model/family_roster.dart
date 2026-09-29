import 'package:flutter/foundation.dart';

import '../../household/model/member.dart';
import 'family_entry.dart';
import 'family_profile.dart';
import 'school.dart';

/// The household's people with what is known about each — the read API other
/// features consume (family-profiles overview, *Contracts*).
///
/// Built from three live reads: the members (household's), the profiles and
/// the schools (this feature's). Everybody on the member list has an entry,
/// whether or not a profile document exists yet; a profile whose member has
/// gone is dropped, because the member is what says a person is here.
@immutable
class FamilyRoster {
  FamilyRoster({
    required List<Member> members,
    required List<FamilyProfile> profiles,
    required List<School> schools,
  }) : schools = List.unmodifiable(
         <School>[...schools]..sort((a, b) => a.name.compareTo(b.name)),
       ),
       entries = List.unmodifiable(_join(members, profiles, schools));

  /// In the member list's order, which is by name.
  final List<FamilyEntry> entries;

  /// By name.
  final List<School> schools;

  static List<FamilyEntry> _join(
    List<Member> members,
    List<FamilyProfile> profiles,
    List<School> schools,
  ) {
    final profileById = {for (final profile in profiles) profile.id: profile};
    final schoolById = {for (final school in schools) school.id: school};
    return [
      for (final member in members)
        FamilyEntry(
          member: member,
          profile: profileById[member.id] ?? FamilyProfile.empty(member.id),
          school: schoolById[profileById[member.id]?.schoolId],
        ),
    ];
  }

  bool get isEmpty => entries.isEmpty;

  List<FamilyEntry> get children =>
      entries.where((entry) => entry.isChild).toList();

  List<FamilyEntry> get everyoneElse =>
      entries.where((entry) => !entry.isChild).toList();

  /// How many child profiles the household has — the number the free tier is
  /// counted by (subscriptions overview).
  int get childCount => children.length;

  FamilyEntry? entryFor(String memberId) =>
      entries.where((entry) => entry.memberId == memberId).firstOrNull;

  School? schoolById(String? schoolId) =>
      schools.where((school) => school.id == schoolId).firstOrNull;

  /// How many people a school is set for, so deleting one can say what it
  /// will change.
  int pupilsAt(String schoolId) =>
      entries.where((entry) => entry.profile.schoolId == schoolId).length;
}
