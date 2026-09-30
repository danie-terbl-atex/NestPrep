/**
 * Medicine (family-profiles ADR-0001): what each person takes and when, as
 * minutes since midnight on the household's clock; an empty list is "when
 * needed". Read only by those holding the `medical` grant.
 */
import { minuteOf, writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { gran, lerato, sipho, zoe } = WHO;

/** member → [id, name, dose, times, note] */
const MEDICATIONS = {
  [lerato]: [
    [
      'm1',
      'Asthma pump (blue reliever)',
      '2 puffs',
      [],
      'When wheezy, and before swimming if she coughs.',
    ],
    [
      'm2',
      'Preventer inhaler (brown)',
      '1 puff',
      ['07:00', '19:30'],
      'Rinse her mouth afterwards.',
    ],
  ],
  [sipho]: [['m1', 'EpiPen Jr', '0.15 mg', [], 'Anaphylaxis only — then call 10177.']],
  [zoe]: [['m1', 'Vitamin drops', '0.5 ml', ['08:00'], 'In her porridge.']],
  [gran]: [['m1', 'Blood-pressure tablet', '1 tablet', ['08:00'], 'With breakfast.']],
};

export async function seedHealth(ctx) {
  const docs = Object.entries(MEDICATIONS).map(([memberId, list]) => [
    ctx.col('memberHealth').doc(memberId),
    {
      medications: Object.fromEntries(
        list.map(([id, name, dose, times, note]) => [
          id,
          { name, dose, times: times.map(minuteOf), note },
        ]),
      ),
    },
  ]);
  await writeAll(ctx.store, docs);
  return `health: medicine for ${String(docs.length)} people`;
}
