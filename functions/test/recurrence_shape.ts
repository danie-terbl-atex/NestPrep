/**
 * A recurrence rule exactly as the Flutter client stores one.
 *
 * The client is the only thing that writes this map — Security Rules check that
 * `recurrence` is one of the allowed keys and say nothing about what is inside
 * it, so a test that invents its own shape is accepted by the emulator and
 * proves nothing. One fixture here did: it wrote `kind` where the client writes
 * `frequency`, and left `until` out, which would have read to the next person as
 * the contract.
 *
 * `test/unit/recurrence_contract.test.ts` reads the generated Dart converter and
 * fails if this drifts from it.
 */
export const RECURRENCE_KEYS = ['frequency', 'interval', 'weekdays', 'until'] as const;

/** Every value `frequency` may hold, as the Dart enum serialises them. */
export const RECURRENCE_FREQUENCIES = ['daily', 'weekly', 'monthly'] as const;

export type RecurrenceFrequency = (typeof RECURRENCE_FREQUENCIES)[number];

export interface StoredRecurrence {
  frequency: RecurrenceFrequency;
  interval: number;
  /** ISO weekdays, Monday 1 to Sunday 7. Empty means "the first occurrence's". */
  weekdays: number[];
  /** `YYYY-MM-DD`, inclusive. Null repeats forever. */
  until: string | null;
}

/**
 * Weekly on Saturday, for ever — the shape a client writes for "every weekend".
 * `interval` and `weekdays` are always present because the Dart fields have
 * defaults, and a default is still written.
 */
export function weeklyOn(weekdays: number[], until: string | null = null): StoredRecurrence {
  return { frequency: 'weekly', interval: 1, weekdays, until };
}

export function everyDay(interval = 1, until: string | null = null): StoredRecurrence {
  return { frequency: 'daily', interval, weekdays: [], until };
}
