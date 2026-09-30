/**
 * Home care (home-care ADR-0001 onward): the rooms, the cleaning products
 * with their stock (the bleach running low, which the `addLowStockToGroceries`
 * trigger puts on the list), three jobs for Thandi — one to do, one waiting
 * for review with before and after photos, one approved — and her room
 * routines with this week's ticks. Each job's events walk its status honestly,
 * because the app reads the revision off them.
 */
import { weekdayOf, writeAll } from './context.mjs';
import { WHO } from './cast.mjs';
import { PHOTO, grimeMarks, uploadPhoto } from './home-care-photos.mjs';

const { mom, helper } = WHO;

const ROOMS = [
  ['kitchen', 'Kitchen', 'kitchen'],
  ['lounge', 'Lounge', 'lounge'],
  ['main-bathroom', 'Main bathroom', 'bathroom'],
  ['kids-bathroom', "Kids' bathroom", 'bathroom'],
  ['lerato-room', "Lerato's room", 'kidsRoom'],
  ['boys-room', "Sipho and Zoë's room", 'kidsRoom'],
  ['laundry', 'Laundry', 'laundry'],
  ['garden', 'Garden and stoep', 'outside'],
];

/** [id, name, kind, where kept, stock, from children, from pets, note] */
const PRODUCTS = [
  [
    'bleach',
    'Jik bleach',
    'bleach',
    'Top shelf in the laundry',
    'low',
    true,
    true,
    'Never with the toilet cleaner.',
  ],
  ['handy-andy', 'Handy Andy', 'allPurpose', 'Under the kitchen sink', 'half', true, false, null],
  [
    'sunlight',
    'Sunlight dishwashing liquid',
    'dishSoap',
    'Next to the sink',
    'full',
    false,
    false,
    null,
  ],
  ['mr-min', 'Mr Min furniture polish', 'polish', 'Laundry cupboard', 'full', true, false, null],
  [
    'toilet',
    'Toilet cleaner',
    'acidic',
    'Behind each toilet, up high',
    'half',
    true,
    true,
    'Gloves on.',
  ],
  [
    'oven',
    'Oven cleaner',
    'ovenCleaner',
    'Top shelf in the laundry',
    'full',
    true,
    true,
    'Open the window first.',
  ],
  [
    'bicarb',
    'Bicarbonate of soda',
    'bicarbonate',
    'Pantry',
    'full',
    false,
    false,
    'Good on the oven door with vinegar.',
  ],
  ['floor', 'Floor cleaner', 'floorCleaner', 'Laundry cupboard', 'full', true, false, null],
];

const shower = [
  { id: 's1', text: 'Spray the glass and leave it five minutes' },
  { id: 's2', text: 'Scrub the marked spots with the soft sponge' },
  { id: 's3', text: 'Rinse and squeegee dry' },
];
const oven = [
  { id: 's1', text: 'Take the racks out to soak' },
  { id: 's2', text: 'Oven cleaner on the inside, window open' },
  { id: 's3', text: 'Wipe out and put the racks back' },
];
const windows = [
  { id: 's1', text: 'Wash the inside panes' },
  { id: 's2', text: 'Wipe the sills' },
];

/** [id, title, room, due, steps, products, statuses walked] */
function jobs(day) {
  return [
    ['shower', 'Clean the shower glass', 'main-bathroom', day(3), shower, ['bleach'], ['assigned']],
    [
      'oven',
      'Deep-clean the oven',
      'kitchen',
      day(1),
      oven,
      ['oven', 'bicarb'],
      ['assigned', 'inProgress', 'submitted'],
    ],
    [
      'windows',
      'Wash the lounge windows',
      'lounge',
      day(-3),
      windows,
      [],
      ['assigned', 'inProgress', 'submitted', 'approved'],
    ],
  ];
}

const ROUTINES = [
  [
    'kitchen-daily',
    'Kitchen — every day',
    'kitchen',
    'daily',
    { frequency: 'weekly', interval: 1, weekdays: [1, 2, 3, 4, 5], until: null },
    ['Wipe the counters', 'Sweep and mop', 'Empty the bin', 'Wipe the fridge handles'],
  ],
  [
    'bathrooms-weekly',
    'Bathrooms — weekly',
    'kids-bathroom',
    'weekly',
    { frequency: 'weekly', interval: 1, weekdays: [2], until: null },
    ['Scrub the bath', 'Toilet and basin', 'Fresh towels', 'Mop the floor'],
  ],
  [
    'fridge-deep',
    'Fridge deep clean',
    'kitchen',
    'deepClean',
    { frequency: 'monthly', interval: 1, weekdays: [], until: null },
    ['Empty and check dates', 'Wash the shelves', 'Wipe the seals'],
  ],
];

export async function seedHomeCare(ctx) {
  const { day, at, col, ago } = ctx;
  const docs = ROOMS.map(([id, name, kind]) => [
    col('homeCareRooms').doc(`demo-${id}`),
    { name, kind, createdBy: mom, createdAt: at(day(-30), '20:00') },
  ]);
  for (const [id, name, kind, whereKept, stock, children, pets, note] of PRODUCTS) {
    docs.push([
      col('homeCareProducts').doc(`demo-${id}`),
      {
        name,
        kind,
        whereKept,
        note,
        keepFromChildren: children,
        keepFromPets: pets,
        createdBy: mom,
        createdAt: at(day(-30), '20:10'),
        stock,
        stockChangedBy: stock === 'full' ? mom : helper,
        stockChangedAt: stock === 'full' ? at(day(-30), '20:10') : ago(5),
      },
    ]);
  }

  for (const [id, title, room, dueDate, steps, products, walk] of jobs(day)) {
    const jobId = `demo-${id}`;
    const revision = walk.length - 1;
    const status = walk[revision];
    const submitted = walk.includes('submitted');
    await uploadPhoto(ctx, jobId, 'before', 'before.jpg');
    if (submitted)
      await uploadPhoto(ctx, jobId, `after-${String(walk.indexOf('submitted'))}`, 'after.jpg');
    const createdAt = at(day(-4), '19:00');
    docs.push([
      col('homeCareJobs').doc(jobId),
      {
        title,
        roomId: `demo-${room}`,
        helperId: helper,
        dueDate,
        note:
          id === 'shower'
            ? 'The marks by the tap are hard water — use the bleach sparingly.'
            : null,
        productIds: products.map((product) => `demo-${product}`),
        steps,
        doneStepIds: submitted ? steps.map((step) => step.id) : [],
        beforePhoto: { photoId: 'before', ...PHOTO },
        marks: grimeMarks(),
        afterPhoto: submitted
          ? { photoId: `after-${String(walk.indexOf('submitted'))}`, ...PHOTO }
          : null,
        status,
        reviewNote: null,
        revision,
        createdBy: mom,
        createdAt,
        updatedAt: revision === 0 ? createdAt : ago(3 + 20 * (status === 'approved' ? 1 : 0)),
      },
    ]);
    walk.forEach((step, index) => {
      docs.push([
        col('homeCareJobs').doc(jobId).collection('events').doc(String(index)),
        {
          status: step,
          by: step === 'assigned' || step === 'approved' ? mom : helper,
          // A note travels only with a send-back.
          note: null,
          at: index === 0 ? createdAt : ago(3 + 20 * (walk.length - 1 - index)),
        },
      ]);
    });
  }

  let ticks = 0;
  for (const [id, name, room, cadence, recurrence, items] of ROUTINES) {
    const routineId = `demo-${id}`;
    const itemList = items.map((text, index) => ({ id: `i${String(index + 1)}`, text }));
    docs.push([
      col('homeCareRoutines').doc(routineId),
      {
        name,
        roomId: `demo-${room}`,
        cadence,
        items: itemList,
        helperId: helper,
        firstDate: day(-7),
        recurrence,
        createdBy: mom,
        createdAt: at(day(-10), '20:00'),
      },
    ]);
    if (cadence !== 'daily') continue;
    // This week's kitchen ticks: Monday and Tuesday done, today half done.
    for (let weekday = 1; weekday <= Math.min(5, weekdayOf(ctx.today)); weekday += 1) {
      const date = day(weekday - 1);
      const done = weekday === weekdayOf(ctx.today) ? itemList.slice(0, 2) : itemList;
      docs.push([
        col('homeCareRoutineTicks').doc(`${routineId}_${date}`),
        {
          routineId,
          occurrenceDate: date,
          helperId: helper,
          doneItemIds: done.map((item) => item.id),
          updatedBy: helper,
          updatedAt: at(date, '11:00'),
        },
      ]);
      ticks += 1;
    }
  }
  docs.push([
    col('homeCareHelpers').doc(helper),
    { language: 'en', updatedBy: mom, updatedAt: at(day(-30), '20:00') },
  ]);

  await writeAll(ctx.store, docs);
  return `home care: ${String(ROOMS.length)} rooms, ${String(PRODUCTS.length)} products (1 low), 3 jobs (to do, to review, done) with photos, ${String(ROUTINES.length)} routines, ${String(ticks)} tick days`;
}
