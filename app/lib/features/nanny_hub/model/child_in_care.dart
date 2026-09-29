import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../family_profiles/model/family_profile.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../family_profiles/model/school.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import 'child_card.dart';

/// What family profiles says about the household's food, as far as the viewer
/// may read it: every profile and school, while loading, failed, or — for a
/// viewer the `familyProfiles` grant does not open — null (nanny-hub
/// ADR-0003).
typedef FamilyFood = ({List<FamilyProfile> profiles, List<School> schools});

/// One child as the hub shows them: the member household owns, the card this
/// feature owns, and what they cannot eat, read straight from their family
/// profile. Joined once so no screen joins them twice.
@immutable
class ChildInCare {
  const ChildInCare({
    required this.member,
    required this.card,
    required this.food,
  });

  final Member member;
  final ChildCard card;

  /// Null when the viewer may not read this child's profile — which is not
  /// "no allergies", and the card says so rather than showing nothing.
  /// Otherwise the read's own state, so a slow or failed read of the
  /// allergies is shown as that, in place, without holding up the card.
  final AsyncState<FoodRules>? food;

  String get memberId => member.id;

  /// Who the hub has a card for: every kid profile, every member a parent
  /// marked as a child in family profiles, and anybody who already has a
  /// card — by name.
  static List<ChildInCare> gather({
    required List<Member> members,
    required Map<String, ChildCard> cards,
    required AsyncState<FamilyFood>? family,
    required bool Function(String memberId) canSeeAllergiesOf,
  }) {
    final known = switch (family) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final profileById = {
      for (final profile in known?.profiles ?? const <FamilyProfile>[])
        profile.id: profile,
    };
    final schoolById = {
      for (final school in known?.schools ?? const <School>[])
        school.id: school,
    };
    bool isChild(Member member) =>
        member.role == MemberRole.kid ||
        cards.containsKey(member.id) ||
        (profileById[member.id]?.isChild ?? false);

    AsyncState<FoodRules>? foodOf(String memberId) {
      if (family == null || !canSeeAllergiesOf(memberId)) return null;
      return switch (family) {
        AsyncLoading() => const AsyncLoading(),
        AsyncFailure(:final failure) => AsyncFailure(failure),
        AsyncData() => AsyncData(
          FoodRules(
            profile: profileById[memberId] ?? FamilyProfile.empty(memberId),
            school: schoolById[profileById[memberId]?.schoolId],
          ),
        ),
      };
    }

    return [
      for (final member in members)
        if (isChild(member))
          ChildInCare(
            member: member,
            card: cards[member.id] ?? ChildCard.empty(member.id),
            food: foodOf(member.id),
          ),
    ]..sort((a, b) => a.member.displayName.compareTo(b.member.displayName));
  }
}
