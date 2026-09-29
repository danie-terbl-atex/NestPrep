import 'access_grant.dart';
import 'access_level.dart';
import 'household_area.dart';
import 'member_role.dart';

/// Where a new kid, helper or carer starts, before a parent changes anything
/// (household ADR-0003). `functions/src/household/access.ts` holds the same
/// table for the Functions, and `access_contract_test.dart` reads both.
abstract final class AccessDefaults {
  /// Null for family, who hold no grant.
  static AccessGrant? forRole(MemberRole role) => switch (role) {
    MemberRole.admin || MemberRole.parent => null,
    MemberRole.kid => kid,
    MemberRole.helper => helper,
    MemberRole.carer => carer,
  };

  static final kid = AccessGrant({
    HouseholdArea.calendar: AccessLevel.view,
    HouseholdArea.groceries: AccessLevel.view,
    HouseholdArea.todos: AccessLevel.own,
    HouseholdArea.meals: AccessLevel.view,
    HouseholdArea.lunch: AccessLevel.own,
    HouseholdArea.familyProfiles: AccessLevel.own,
  });

  static final helper = AccessGrant({
    HouseholdArea.calendar: AccessLevel.view,
    HouseholdArea.groceries: AccessLevel.edit,
    HouseholdArea.todos: AccessLevel.own,
    HouseholdArea.meals: AccessLevel.view,
    HouseholdArea.homeCare: AccessLevel.own,
  });

  static final carer = AccessGrant({
    HouseholdArea.calendar: AccessLevel.view,
    HouseholdArea.groceries: AccessLevel.view,
    HouseholdArea.todos: AccessLevel.own,
    HouseholdArea.meals: AccessLevel.view,
    HouseholdArea.lunch: AccessLevel.view,
    HouseholdArea.familyProfiles: AccessLevel.view,
    HouseholdArea.medical: AccessLevel.view,
    HouseholdArea.nannyHub: AccessLevel.edit,
  });

  /// What a helper claimed before ADR-0003 still holds until a parent chooses:
  /// everything, as every helper had.
  static final legacyHelper = AccessGrant.uniform(AccessLevel.edit);
}
