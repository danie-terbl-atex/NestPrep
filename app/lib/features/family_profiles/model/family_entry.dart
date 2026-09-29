import 'package:flutter/foundation.dart';

import '../../household/model/member.dart';
import 'family_profile.dart';
import 'food_rules.dart';
import 'school.dart';

/// One person as the family screens and every reader of family profiles see
/// them: the member household owns, the profile this feature owns, and the
/// school it points at — joined once so nobody joins them twice.
@immutable
class FamilyEntry {
  FamilyEntry({required this.member, required this.profile, this.school})
    : foodRules = FoodRules(profile: profile, school: school);

  final Member member;
  final FamilyProfile profile;

  /// Null when no school is set, or the one set has since been deleted.
  final School? school;
  final FoodRules foodRules;

  String get memberId => member.id;

  bool get isChild => profile.isChild;
}
