/**
 * Every field any analytics document may carry, by collection
 * (product-analytics ADR-0001, `ENG-22`).
 *
 * The unit tests check the builders against it and the emulator test checks
 * what was actually written. A new field means editing this list, which is the
 * moment somebody should ask whether it identifies a person — a name, an email,
 * anything about a child — and the answer has to be no.
 */
export const ALLOWED_FIELDS: Readonly<Record<string, readonly string[]>> = {
  analyticsHouseholdWeeks: ['householdId', 'week', 'activeMemberIds', 'lunchPlanIds', 'expireAt'],
  analyticsHouseholds: [
    'householdId',
    'createdAt',
    'cohortWeek',
    'firstAdultInviteAt',
    'firstAdultInviteRole',
    'expireAt',
  ],
  analyticsConversions: ['householdId', 'week', 'trigger', 'convertedAt', 'expireAt'],
  analyticsWeeks: [
    'week',
    'weekStart',
    'activeFamilies',
    'familiesSeen',
    'lunchPlansCreated',
    'familiesPlanningLunches',
    'newFamilies',
    'newFamiliesInvitingAnAdult',
    'adultInvitesByRole',
    'isInviteCohortComplete',
    'premiumConversions',
    'premiumConversionsByTrigger',
    'definitionVersion',
    'computedAt',
  ],
};

/** Field names that would mean somebody's identity or a child's details leaked in. */
export const FORBIDDEN_FIELD_WORDS = [
  'name',
  'email',
  'displayName',
  'uid',
  'allerg',
  'medication',
  'school',
  'birthday',
  'code',
  'location',
  'content',
];
