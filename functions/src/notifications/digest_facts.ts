/**
 * One household's day, as the morning digest reads it (notifications
 * ADR-0002): what is already stored, resolved to *today* on the household's
 * clock, and nothing else. The loader fills it with bounded reads; the
 * composer turns it into one person's summary, filtered by what that person
 * may see. Nothing here is stored — a digest is a read of what exists.
 */

export interface DayEvent {
  readonly title: string;
  /** Minutes after local midnight; null is all day. */
  readonly startMinute: number | null;
  /** Who it is for. Empty is everyone. */
  readonly memberIds: readonly string[];
}

export interface LunchBoxToday {
  readonly childId: string;
  /** What is in the box, by name — never its allergens (ADR-0002). */
  readonly items: readonly string[];
}

export interface ChoreToday {
  readonly title: string;
  /** Who it is for, the routine's defaults applied. Empty is anyone. */
  readonly assigneeIds: readonly string[];
}

export interface ExpiringDocument {
  readonly name: string;
  /** `YYYY-MM-DD` on the household's clock. */
  readonly expiresOn: string;
}

export interface OpenShift {
  readonly carerMemberId: string;
  readonly startedAt: Date;
}

export interface RecentHandover {
  readonly carerMemberId: string;
  readonly entryCount: number;
}

export interface HouseholdDay {
  /** `YYYY-MM-DD` on the household's clock. */
  readonly today: string;
  readonly zone: string;
  /** memberId → the name the household gave them. */
  readonly names: Readonly<Record<string, string>>;
  readonly events: readonly DayEvent[];
  readonly lunchBoxes: readonly LunchBoxToday[];
  readonly chores: readonly ChoreToday[];
  readonly documents: readonly ExpiringDocument[];
  /** memberId → what in their own vault is expiring. */
  readonly vaults: Readonly<Record<string, readonly ExpiringDocument[]>>;
  readonly openShifts: readonly OpenShift[];
  readonly handovers: readonly RecentHandover[];
  readonly choresToCheck: number;
  readonly rewardsAskedFor: number;
}
