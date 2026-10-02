/**
 * What a non-family member may see and do, per area (household ADR-0003).
 *
 * These names are a contract. `firestore.rules`, `storage.rules` and the app's
 * `household_area.dart` spell them the same way, and a test on each side reads
 * this file to prove it — an area renamed here and nowhere else would be a door
 * that silently stops opening.
 */
export const AREAS = [
  'calendar',
  'groceries',
  'todos',
  'meals',
  'documents',
  'lunch',
  'familyProfiles',
  'medical',
  'homeCare',
  'nannyHub',
] as const;
export type Area = (typeof AREAS)[number];

export const LEVELS = ['none', 'own', 'view', 'edit'] as const;
export type Level = (typeof LEVELS)[number];

export type Grant = Record<Area, Level>;

/**
 * Which levels each area accepts. `own` exists only where "theirs" means
 * something — a task's assignees, a child's lunches, a profile's own member, a
 * helper's jobs.
 */
export const AREA_LEVELS: Record<Area, readonly Level[]> = {
  calendar: ['none', 'view', 'edit'],
  groceries: ['none', 'view', 'edit'],
  todos: ['none', 'own', 'view', 'edit'],
  meals: ['none', 'view', 'edit'],
  documents: ['none', 'view', 'edit'],
  lunch: ['none', 'own', 'view', 'edit'],
  familyProfiles: ['none', 'own', 'view', 'edit'],
  medical: ['none', 'own', 'view', 'edit'],
  homeCare: ['none', 'own', 'view', 'edit'],
  nannyHub: ['none', 'view', 'edit'],
};

/** The areas whose bytes live in Cloud Storage, and so travel on the token. */
export const STORAGE_AREAS: readonly Area[] = [
  'documents',
  'homeCare',
  'nannyHub',
  'familyProfiles',
  'medical',
  'lunch',
];

/** Roles whose members see and do everything, as every member did before. */
export const FAMILY_ROLES = ['admin', 'parent', 'member'] as const;

export type RestrictedRole = 'kid' | 'helper' | 'carer';

/**
 * A new kid, helper or carer starts here; the parent changes it afterwards.
 * `access_defaults.dart` holds the same table, and a test reads both.
 */
export const ROLE_DEFAULTS: Record<RestrictedRole, Grant> = {
  kid: {
    calendar: 'view',
    groceries: 'view',
    todos: 'own',
    meals: 'view',
    documents: 'none',
    lunch: 'own',
    familyProfiles: 'own',
    medical: 'none',
    homeCare: 'none',
    nannyHub: 'none',
  },
  helper: {
    calendar: 'view',
    groceries: 'edit',
    todos: 'own',
    meals: 'view',
    documents: 'none',
    lunch: 'none',
    familyProfiles: 'none',
    medical: 'none',
    homeCare: 'own',
    nannyHub: 'none',
  },
  carer: {
    calendar: 'view',
    groceries: 'view',
    todos: 'own',
    meals: 'view',
    documents: 'none',
    lunch: 'view',
    familyProfiles: 'view',
    medical: 'view',
    homeCare: 'none',
    nannyHub: 'edit',
  },
};

export function isFamilyRole(role: string): boolean {
  return (FAMILY_ROLES as readonly string[]).includes(role);
}

export function isRestrictedRole(role: string): role is RestrictedRole {
  return role === 'kid' || role === 'helper' || role === 'carer';
}

/** Every area at one level — what a legacy helper holds until a parent chooses. */
export function uniformGrant(level: Level): Grant {
  return Object.fromEntries(AREAS.map((area) => [area, level])) as Grant;
}

/**
 * A stored grant, read defensively: an unknown area is dropped, an area missing
 * is `none`, and a level the area does not accept is `none` — so a bad value
 * narrows access rather than widening it (household ADR-0003, BE-10).
 */
export function readGrant(stored: unknown): Grant | null {
  if (stored === null || typeof stored !== 'object' || Array.isArray(stored)) return null;
  const source = stored as Record<string, unknown>;
  const grant = uniformGrant('none');
  for (const area of AREAS) {
    const level = source[area];
    if (typeof level === 'string' && (AREA_LEVELS[area] as readonly string[]).includes(level)) {
      grant[area] = level as Level;
    }
  }
  return grant;
}

/**
 * The grant a household records for a member claiming this profile, or null
 * for a family role, which needs none. A profile with no stored grant gets its
 * role's defaults.
 */
export function effectiveGrant(role: string, stored: unknown): Grant | null {
  if (!isRestrictedRole(role)) return null;
  return readGrant(stored) ?? { ...ROLE_DEFAULTS[role] };
}

/**
 * What one member may do in one area — the Functions' copy of `levelIn` in the
 * rules (`rules/firestore/shared/access.rules`): family `edit`; a kid, helper
 * or carer what their recorded grant says; a helper with none recorded —
 * claimed before household ADR-0003 — `edit`; anybody else `none`.
 */
export function memberLevelIn(role: string, storedGrant: unknown, area: Area): Level {
  if (isFamilyRole(role)) return 'edit';
  const grant = readGrant(storedGrant);
  if (grant === null) return role === 'helper' ? 'edit' : 'none';
  return grant[area];
}

/** Only the areas the bytes live under, and only where the level is not none. */
export function storageGrant(grant: Grant): Partial<Record<Area, Level>> {
  const result: Partial<Record<Area, Level>> = {};
  for (const area of STORAGE_AREAS) {
    if (grant[area] !== 'none') result[area] = grant[area];
  }
  return result;
}
