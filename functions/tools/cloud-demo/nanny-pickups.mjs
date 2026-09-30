/**
 * Who collects the children (nanny-hub pickups): the two people besides the
 * family who may, the weekly school run per child and weekday — Lindiwe most
 * days, Ouma on Wednesdays, the lift club on Fridays — and Thursday's change,
 * Dad fetching Lerato from swimming.
 */
import { minuteOf, writeAll } from './context.mjs';
import { WHO } from './cast.mjs';

const { mom, dad, gran, nanny, lerato, sipho } = WHO;

const PICKUP_PEOPLE = [
  [
    'zanele',
    'Zanele Dube',
    'Lift club',
    'Drives a silver Toyota Avanza.',
    '+27 82 555 0110',
    [lerato, sipho],
  ],
  [
    'mr-naidoo',
    'Mr Naidoo',
    'Swimming coach',
    'May walk Lerato to the gate after swimming.',
    null,
    [lerato],
  ],
];

/** School runs: [child, weekday, who (member or pickup person), time, place] */
const RUNS = [
  [sipho, 1, { memberId: nanny }, '12:30', 'Grade R gate'],
  [sipho, 2, { memberId: nanny }, '12:30', 'Grade R gate'],
  [sipho, 3, { memberId: gran }, '12:30', 'Grade R gate'],
  [sipho, 4, { memberId: nanny }, '12:30', 'Grade R gate'],
  [sipho, 5, { personId: 'demo-zanele' }, '12:30', 'Grade R gate'],
  [lerato, 1, { memberId: nanny }, '14:30', 'Main gate'],
  [lerato, 2, { memberId: nanny }, '16:30', 'Swimming pool'],
  [lerato, 3, { memberId: gran }, '14:30', 'Main gate'],
  [lerato, 4, { memberId: nanny }, '16:30', 'Swimming pool'],
  [lerato, 5, { personId: 'demo-zanele' }, '14:30', 'Main gate'],
];

export async function seedNannyPickups(ctx) {
  const { day, at, col, ago } = ctx;
  const created = at(day(-21), '20:00');
  const docs = [];
  PICKUP_PEOPLE.forEach(([id, name, relationship, idNote, phone, childIds]) =>
    docs.push([
      col('nannyPickupPeople').doc(`demo-${id}`),
      {
        name,
        relationship,
        idNote,
        phone,
        photoId: null,
        childIds: [...childIds].sort(),
        createdBy: mom,
        createdAt: created,
      },
    ]),
  );
  for (const [childId, weekday, who, time, place] of RUNS) {
    docs.push([
      col('nannySchoolRuns').doc(`${childId}_${String(weekday)}`),
      {
        childId,
        weekday,
        personId: who.personId ?? null,
        memberId: who.memberId ?? null,
        atMinute: minuteOf(time),
        place,
        updatedBy: mom,
        updatedAt: created,
      },
    ]);
  }
  const thursday = day(3);
  docs.push([
    col('nannyPickupChanges').doc(`${lerato}_${thursday}`),
    {
      childId: lerato,
      date: thursday,
      personId: null,
      memberId: dad,
      atMinute: minuteOf('16:30'),
      note: 'Dad fetches from swimming — Lindiwe goes straight home with the little ones.',
      updatedBy: mom,
      updatedAt: ago(2),
    },
  ]);

  await writeAll(ctx.store, docs);
  return `pickups: ${String(PICKUP_PEOPLE.length)} people, ${String(RUNS.length)} school runs, 1 change`;
}
