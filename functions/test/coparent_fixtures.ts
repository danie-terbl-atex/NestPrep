/**
 * Parenting schedules exactly as the Flutter client sends them (household
 * ADR-0004), shared by the unit, rules and emulator suites so none of them
 * invents its own shape. `app/test/features/two_homes/model/custody_contract_test.dart`
 * reads this file and fails if the client's presets stop producing these.
 */

const ALL_WEEK = [1, 2, 3, 4, 5, 6, 7];

/** Alternating weeks from Monday 28 September 2026, changing homes on Monday. */
export const ALTERNATING = {
  pattern: 'alternatingWeeks',
  startsOn: '2026-09-28',
  cycleWeeks: 2,
  blocks: [
    { side: 'a', weekOffset: 0, weekdays: ALL_WEEK },
    { side: 'b', weekOffset: 1, weekdays: ALL_WEEK },
  ],
  handoverMinute: 17 * 60,
} as const;

/** 2-2-3 from the same Monday: the preset with the most blocks. */
export const TWO_TWO_THREE = {
  pattern: 'twoTwoThree',
  startsOn: '2026-09-28',
  cycleWeeks: 2,
  blocks: [
    { side: 'a', weekOffset: 0, weekdays: [1, 2, 5, 6, 7] },
    { side: 'b', weekOffset: 0, weekdays: [3, 4] },
    { side: 'b', weekOffset: 1, weekdays: [1, 2, 5, 6, 7] },
    { side: 'a', weekOffset: 1, weekdays: [3, 4] },
  ],
  handoverMinute: null,
} as const;

export const MUMS_HOME = { name: 'Mum’s home', color: 'coral' } as const;
export const DADS_HOME = { name: 'Dad’s home', color: 'sky' } as const;
