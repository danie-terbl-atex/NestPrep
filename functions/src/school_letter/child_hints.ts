import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { FAMILY_PROFILES } from '../family_profiles/member_details';
import { MEMBERS, householdRef } from '../household/documents';

/**
 * What the model is told about the household's children so it can say which
 * child an event is for (calendar ADR-0005, foundation ADR-0015's POPIA
 * section): **a placeholder, a school name and a grade — never a name, a
 * birthday, an allergy or anything medical.** `child-1` means nothing outside
 * this request; the mapping back to a member id never leaves the Function.
 */
export interface ChildHint {
  readonly ref: string;
  readonly memberId: string;
  readonly school: string | null;
  readonly grade: string | null;
}

/** A household has a handful of children; this bounds the read regardless (BE-08). */
export const MAX_CHILDREN = 12;

const profileShape = z.object({
  schoolId: z.string().nullable().optional(),
  grade: z.string().nullable().optional(),
});
const schoolShape = z.object({ name: z.string() });

export interface ChildFacts {
  readonly memberId: string;
  readonly schoolId: string | null;
  readonly grade: string | null;
}

/**
 * The hints, from what is stored — pure, so the rule "no school and no grade
 * means nothing to tell" is tested without Firestore. A school that no longer
 * exists reads as no school, as it does in the app (`FamilyRoster`).
 */
export function hintsFrom(
  children: readonly ChildFacts[],
  schoolNames: Readonly<Record<string, string>>,
): ChildHint[] {
  const hints: ChildHint[] = [];
  for (const child of children) {
    const school = child.schoolId === null ? null : (schoolNames[child.schoolId] ?? null);
    const grade = tidy(child.grade);
    if (school === null && grade === null) continue;
    hints.push({
      ref: `child-${String(hints.length + 1)}`,
      memberId: child.memberId,
      school: tidy(school),
      grade,
    });
  }
  return hints;
}

function tidy(value: string | null): string | null {
  const trimmed = value?.trim().slice(0, 80) ?? '';
  return trimmed === '' ? null : trimmed;
}

/** Reads the household's kids, their profiles and their schools. */
export async function readChildHints(store: Firestore, householdId: string): Promise<ChildHint[]> {
  const household = householdRef(store, householdId);
  const kids = await household
    .collection(MEMBERS)
    .where('role', '==', 'kid')
    .limit(MAX_CHILDREN)
    .get();
  if (kids.empty) return [];

  const profiles = await store.getAll(
    ...kids.docs.map((kid) => household.collection(FAMILY_PROFILES).doc(kid.id)),
  );
  const children: ChildFacts[] = profiles.map((profile) => {
    const parsed = profileShape.safeParse(profile.data() ?? {});
    return {
      memberId: profile.id,
      schoolId: parsed.success ? (parsed.data.schoolId ?? null) : null,
      grade: parsed.success ? (parsed.data.grade ?? null) : null,
    };
  });

  const schoolIds = [...new Set(children.flatMap((child) => child.schoolId ?? []))];
  const schools =
    schoolIds.length === 0
      ? []
      : await store.getAll(...schoolIds.map((id) => household.collection('schools').doc(id)));
  const schoolNames: Record<string, string> = {};
  for (const school of schools) {
    const parsed = schoolShape.safeParse(school.data());
    if (parsed.success) schoolNames[school.id] = parsed.data.name;
  }
  return hintsFrom(children, schoolNames);
}
