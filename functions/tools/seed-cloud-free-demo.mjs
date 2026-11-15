#!/usr/bin/env node
/**
 * Seeds the free demo family into the real project, beside the Premium one
 * of `seed-cloud-demo.mjs` (foundation ADR-0019): two accounts under fixed
 * `free-` uids and *The Maple Lane Nest* they share with one child — no
 * entitlement, so it is a free household with its one free child — and a
 * light week in the free areas: calendar, to-dos, groceries, meals.
 *
 * Every write is to the two `free-` users or the `free-` household.
 * `appConfig/flags`, the demo household and every other household are
 * neither read nor written. Safe to run again: ids are fixed and writes
 * overwrite.
 *
 *     npm run build && npm run seed:cloud-free-demo
 *
 * Needs application-default credentials and `app/demo_logins.json` for the
 * one password, shared with the demo accounts; `-- --reset-password` sets it
 * again. Prints counts and addresses only, never the password (ENG-18).
 */
import { seedAccount } from './cloud-demo/accounts.mjs';
import { assertScope, connect, demoPassword } from './cloud-demo/admin.mjs';
import { addDays, createContext, minuteOf, writeAll } from './cloud-demo/context.mjs';
import { FREE_CAST, FREE_PREFIX, FREE_WHO } from './cloud-demo/free-cast.mjs';
import { seedDemoHousehold } from './demo-household.mjs';

const { mom, dad, child } = FREE_WHO;

assertScope(FREE_CAST, FREE_PREFIX);
const password = demoPassword();
const { target, store, auth } = connect();
console.log(`seeding the free demo family into ${target}\n`);

const resetPassword = process.argv.includes('--reset-password');
const weekly = (weekdays) => ({ frequency: 'weekly', interval: 1, weekdays, until: null });
const daily = { frequency: 'daily', interval: 1, weekdays: [], until: null };

/**
 * [id, title, offset, start, end, memberIds, createdBy, recurrence?, note?].
 * What repeats weekly counts its offset from this Monday; anything else counts
 * from the day the seed runs, so nothing is overdue whichever weekday that is.
 */
const EVENTS = [
  ['school-run', 'School run', 0, '07:15', '07:45', [dad, child], dad, weekly([1, 2, 3, 4, 5])],
  [
    'ballet',
    'Ballet — Kayla',
    1,
    '15:00',
    '16:00',
    [child, mom],
    mom,
    weekly([2]),
    'Hair in a bun.',
  ],
  ['dentist', 'Dentist — Kayla', 1, '10:30', '11:00', [child, mom], mom, null, 'Check-up.'],
  ['library-day', 'Library day', 2, null, null, [child], mom],
  ['five-a-side', 'Five-a-side', 3, '18:00', '19:00', [dad], dad],
  ['granny-visit', 'Lunch at Granny’s', 5, '12:30', '15:00', [], mom],
];

/** [id, title, dueOffset, assignees, createdBy, options] — offsets as for the events. */
const TASKS = [
  [
    'school-fees',
    'Pay school fees',
    4,
    [mom],
    mom,
    { note: 'EFT, use the reference on the invoice.' },
  ],
  ['licence-disc', 'Renew the car licence disc', 5, [dad], mom],
  ['ballet-shoes', 'Buy new ballet shoes', 0, [mom], mom],
  ['electricity', 'Top up the prepaid electricity', 2, [dad], dad],
  ['bins', 'Take the bins out', 0, [dad], dad, { recurrence: weekly([1]) }],
  ['library', 'Return library books', 2, [child], mom, { picture: 'library-book' }],
  ['make-bed', 'Make your bed', 0, [child], mom, { recurrence: daily, picture: 'make-bed' }],
  ['set-table', 'Set the table', 0, [child], dad, { recurrence: daily, picture: 'set-table' }],
];

const DONE = [
  ['bins', dad],
  ['ballet-shoes', mom],
];

/** [name, quantity, addedBy, addedHoursAgo, boughtBy?, boughtHoursAgo?] */
const GROCERIES = [
  ['Milk', '2 l', mom, 20, dad, 3],
  ['Brown bread', '1 loaf', mom, 20, dad, 3],
  ['Eggs', '12', mom, 9],
  ['Bananas', null, mom, 9],
  ['Strawberries', '2 punnets', dad, 6],
  ['Spaghetti', '1 pack', mom, 6],
  ['Beef mince', '500 g', mom, 6],
  ['Cheddar', '400 g', dad, 5],
  ['Toothpaste', null, dad, 4],
  ['Dishwashing liquid', null, mom, 2],
];

/** [id, name, addedBy, ingredients as [name, amount?, unit?]] */
const MEALS = [
  [
    'bolognese',
    'Spaghetti bolognese',
    mom,
    [
      ['Beef mince', 500, 'g'],
      ['Spaghetti', 1, 'pack'],
      ['Chopped tomatoes', 2, 'tin'],
      ['Onion', 1],
    ],
  ],
  [
    'stir-fry',
    'Chicken stir-fry',
    dad,
    [
      ['Chicken breasts', 500, 'g'],
      ['Stir-fry veg', 1, 'pack'],
      ['Egg noodles', 1, 'pack'],
    ],
  ],
  [
    'fish-fingers',
    'Fish fingers, mash and peas',
    mom,
    [
      ['Fish fingers', 1, 'pack'],
      ['Potatoes', 1, 'kg'],
      ['Frozen peas', 1, 'pack'],
    ],
  ],
  [
    'mac-cheese',
    'Mac and cheese',
    mom,
    [
      ['Macaroni', 500, 'g'],
      ['Cheddar', 300, 'g'],
      ['Milk', 500, 'ml'],
    ],
  ],
  [
    'braai',
    'Braai with pap',
    dad,
    [
      ['Boerewors', 1, 'kg'],
      ['Maize meal', 1, 'kg'],
      ['Chakalaka', 1, 'tin'],
    ],
  ],
];

/** This week, then next. */
const PLAN = [
  {
    '1_dinner': 'bolognese',
    '2_dinner': 'stir-fry',
    '3_dinner': 'fish-fingers',
    '4_dinner': 'mac-cheese',
    '6_dinner': 'braai',
    '7_dinner': 'bolognese',
  },
  { '1_dinner': 'mac-cheese', '2_dinner': 'stir-fry', '4_dinner': 'fish-fingers' },
];

const id = (name) => `${FREE_PREFIX}${name}`;
const slug = (name) =>
  name
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '');

const dateOf = ({ day, today }, offset, recurrence) =>
  recurrence?.frequency === 'weekly' ? day(offset) : addDays(today, offset);

function calendar(ctx) {
  const { col, day, at } = ctx;
  return EVENTS.map(
    ([name, title, offset, start, end, memberIds, createdBy, recurrence = null, note = null]) => [
      col('events').doc(id(name)),
      {
        title,
        note,
        date: dateOf(ctx, offset, recurrence),
        startMinute: start === null ? null : minuteOf(start),
        endMinute: end === null ? null : minuteOf(end),
        recurrence,
        memberIds,
        createdBy,
        createdAt: at(day(-7), '20:00'),
      },
    ],
  );
}

function todos(ctx) {
  const { col, day, at } = ctx;
  const due = Object.fromEntries(
    TASKS.map(([name, , offset, , , options = {}]) => [
      name,
      dateOf(ctx, offset, options.recurrence),
    ]),
  );
  const tasks = TASKS.map(([name, title, , assigneeIds, createdBy, options = {}]) => [
    col('tasks').doc(id(name)),
    {
      title,
      note: options.note ?? null,
      dueDate: due[name],
      recurrence: options.recurrence ?? null,
      assigneeIds,
      createdBy,
      routineId: null,
      createdAt: at(day(-3), '20:30'),
      points: 0,
      needsApproval: false,
      picture: options.picture ?? null,
    },
  ]);
  const done = DONE.map(([name, by]) => [
    col('taskCompletions').doc(`${id(name)}_${due[name]}`),
    {
      taskId: id(name),
      occurrenceDate: due[name],
      completedBy: by,
      completedFor: by,
      completedAt: at(due[name], '07:30'),
    },
  ]);
  return [...tasks, ...done];
}

function groceries({ col, ago }) {
  return GROCERIES.map(([name, quantity, addedBy, addedAgo, boughtBy = null, boughtAgo]) => [
    col('groceryItems').doc(id(slug(name))),
    {
      name,
      quantity,
      addedBy,
      addedAt: ago(addedAgo),
      boughtBy,
      boughtAt: boughtBy === null ? null : ago(boughtAgo),
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
    },
  ]);
}

function meals({ col, day, at }) {
  const library = MEALS.map(([name, title, addedBy, ingredients]) => [
    col('meals').doc(id(name)),
    {
      name: title,
      nameKey: title.toLowerCase(),
      addedBy,
      createdAt: at(day(-14), '19:00'),
      ingredients: ingredients.map(([ingredient, amount, unit]) => ({
        name: ingredient,
        ...(amount === undefined ? {} : { amount }),
        ...(unit === undefined ? {} : { unit }),
      })),
    },
  ]);
  const plans = PLAN.map((slots, week) => [
    col('mealPlans').doc(day(week * 7)),
    { slots: Object.fromEntries(Object.entries(slots).map(([slot, name]) => [slot, id(name)])) },
  ]);
  return [...library, ...plans];
}

for (const person of FREE_CAST.people) {
  console.log(await seedAccount(auth, person, { password, resetPassword }));
}
console.log(await seedDemoHousehold(store, FREE_CAST, { premium: false, flags: false }));

const ctx = createContext({ store, cast: FREE_CAST });
console.log(`the week of ${ctx.monday}, today ${ctx.today}`);
for (const [label, part] of Object.entries({ calendar, todos, groceries, meals })) {
  console.log(`${label}: ${String(await writeAll(store, part(ctx)))} documents`);
}
console.log('\ndone — the password is the demo accounts’, in app/demo_logins.json');
