/**
 * The lunch box (lunch-box ADR-0001 onward): the starter library plus two
 * family favourites, last week's and this week's boxes for both school
 * children with thumbs up and down on the days gone, go-to boxes, what was
 * packed, and a day of options for Lerato to choose from (the prep ticks,
 * prices, budget and pantry are `lunch-stock.mjs`). Every pick is checked against the
 * child's allergies (and Sipho's nut-free school) before it is written.
 */
import { isoWeekOf, weekdayOf, writeAll } from './context.mjs';
import { WHO } from './cast.mjs';
import { ALLERGEN_ORDER, lunchStarterSet } from './lunch-starter-set.mjs';

const { mom, dad, gran, lerato, sipho } = WHO;

const FAMILY_ITEMS = [
  {
    id: 'demo-vetkoek',
    name: 'Mini vetkoek with mince',
    slot: 'main',
    allergens: ['wheat'],
    prepNote: 'Fry on Sunday, fill in the morning.',
    addedBy: gran,
  },
  {
    id: 'demo-ouma-rusks',
    name: "Ouma's buttermilk rusks",
    slot: 'treat',
    allergens: ['milk', 'egg', 'wheat'],
    prepNote: null,
    addedBy: gran,
  },
];

/** What each child may not have: their allergies, and nuts at a nut-free school. */
const AVOID = { [lerato]: ['milk'], [sipho]: ['peanut', 'treeNut'] };

/** A school week per child as `slot: [Mon…Fri]` keys; null leaves that day's slot empty. */
const WEEKS = {
  [lerato]: {
    main: ['chicken-mayo', 'rice-salad', 'hummus-pita', 'frikkadels', 'chicken-drumstick'],
    fruit: ['naartjie', 'apple', 'grapes', 'naartjie', 'strawberries'],
    veg: ['carrot-sticks', null, 'cucumber', 'sugar-snaps', null],
    snack: ['biltong', 'popcorn', 'rice-cakes', 'droewors', 'raisins'],
    treat: [null, null, null, null, 'jelly'],
  },
  [sipho]: {
    main: ['pasta-salad', 'cheese-rolls', 'cheese-tomato', 'mealie-bread', 'pasta-salad'],
    fruit: ['grapes', 'banana', 'apple', 'grapes', 'mango'],
    veg: ['cherry-tomatoes', 'baby-corn', null, 'carrot-sticks', null],
    snack: ['cheese-cubes', 'yoghurt', 'pretzels', 'crackers', 'popcorn'],
    treat: [null, null, null, null, 'marie-biscuits'],
  },
};

/** Last week's boxes: this week's, a day later round the week. */
const shifted = (week) =>
  Object.fromEntries(
    Object.entries(week).map(([slot, days]) => [
      slot,
      slot === 'treat' ? days : [...days.slice(1), days[0]],
    ]),
  );

/** Thumbs by [weeksAgo][child]: day → verdict, with a slot left over where there was one. */
const FEEDBACK = {
  1: {
    [lerato]: { 1: ['ate'], 2: ['ate'], 3: ['left', { veg: 'left' }], 4: ['ate'], 5: ['ate'] },
    [sipho]: { 1: ['ate'], 2: ['left', { main: 'left' }], 3: ['ate'], 4: ['ate'], 5: ['ate'] },
  },
  0: {
    [lerato]: { 1: ['ate'], 2: ['ate', { snack: 'left' }] },
    [sipho]: { 1: ['left', { veg: 'left' }], 2: ['ate'] },
  },
};

const FAVOURITES = [
  [lerato, 'wrap-day', 'Wrap day', { main: 'chicken-mayo', fruit: 'naartjie', snack: 'biltong' }],
  [
    lerato,
    'picnic',
    'Picnic box',
    { main: 'chicken-drumstick', veg: 'cucumber', fruit: 'grapes', snack: 'popcorn' },
  ],
  [
    sipho,
    'pasta-power',
    'Pasta power',
    { main: 'pasta-salad', fruit: 'grapes', snack: 'cheese-cubes' },
  ],
  [
    sipho,
    'cheesy-friday',
    'Cheesy Friday',
    { main: 'cheese-rolls', fruit: 'banana', treat: 'marie-biscuits' },
  ],
];

function library() {
  const items = [...lunchStarterSet().map((item) => ({ ...item, addedBy: mom })), ...FAMILY_ITEMS];
  return new Map(items.map((item) => [item.id, item]));
}

export async function seedLunch(ctx) {
  const { day, at, col } = ctx;
  const items = library();
  const todayWeekday = weekdayOf(ctx.today);
  const idOf = (key) => (items.has(`seed-${key}`) ? `seed-${key}` : key);
  const pick = (child, key) => {
    const item = items.get(idOf(key));
    if (item === undefined) throw new Error(`no lunch item ${key}`);
    const clash = item.allergens.filter((code) => AVOID[child].includes(code));
    if (clash.length > 0)
      throw new Error(`${item.name} is not safe for ${child}: ${clash.join(', ')}`);
    return { itemId: item.id, name: item.name, allergens: item.allergens };
  };

  const docs = [...items.values()].map((item) => [
    col('lunchItems').doc(item.id),
    {
      name: item.name,
      nameKey: item.name.toLowerCase(),
      slot: item.slot,
      allergens: ALLERGEN_ORDER.filter((code) => item.allergens.includes(code)),
      prepAhead: item.prepNote !== null,
      prepNote: item.prepNote,
      archived: false,
      seedKey: item.key ?? null,
      addedBy: item.addedBy,
      createdAt: at(day(-28), '19:30'),
    },
  ]);

  const packedToday = [];
  for (const child of [lerato, sipho]) {
    for (const weeksAgo of [1, 0]) {
      const monday = day(-7 * weeksAgo);
      const week = isoWeekOf(monday);
      const plan = weeksAgo === 0 ? WEEKS[child] : shifted(WEEKS[child]);
      const slots = {};
      for (const [slot, days] of Object.entries(plan)) {
        days.forEach((key, index) => {
          if (key !== null) slots[`${String(index + 1)}_${slot}`] = pick(child, key);
        });
      }
      const feedback = {};
      for (const [weekday, [verdict, perSlot]] of Object.entries(FEEDBACK[weeksAgo][child])) {
        // Only days gone by can be marked.
        if (weeksAgo === 0 && Number(weekday) >= todayWeekday) continue;
        feedback[weekday] = {
          verdict,
          ...(perSlot === undefined ? {} : { items: perSlot }),
          by: weekday % 2 === 0 ? dad : mom,
          at: at(day(-7 * weeksAgo + Number(weekday) - 1), '15:10'),
        };
      }
      docs.push([
        col('lunchPlans').doc(`${child}_${week}`),
        { childId: child, week, weekStart: monday, slots, feedback },
      ]);
      if (weeksAgo === 0) {
        // Packed Monday to today, the way marking a box packed records it.
        for (let weekday = 1; weekday <= Math.min(5, todayWeekday); weekday += 1) {
          const date = day(weekday - 1);
          const itemIds = Object.entries(slots)
            .filter(([slotKey]) => slotKey.startsWith(`${String(weekday)}_`))
            .map(([, value]) => value.itemId);
          docs.push([
            col('lunchPacked').doc(`${child}_${date}`),
            {
              childId: child,
              date,
              week,
              itemIds,
              by: weekday === 3 ? WHO.helper : mom,
              at: at(date, '06:50'),
            },
          ]);
          packedToday.push(date);
        }
      }
    }
  }

  const thisWeek = isoWeekOf(ctx.today);
  for (const [child, id, name, picks] of FAVOURITES) {
    docs.push([
      col('lunchFavourites').doc(`demo-${id}`),
      {
        childId: child,
        name,
        picks: Object.fromEntries(
          Object.entries(picks).map(([slot, key]) => [slot, pick(child, key)]),
        ),
        createdBy: mom,
        createdAt: at(day(-20), '20:00'),
      },
    ]);
  }

  // Kid picks: Lerato chooses tomorrow's main and fruit; Sipho already chose Friday's snack.
  const options = (child, slotKey, keys) => [slotKey, keys.map((key) => pick(child, key))];
  docs.push([
    col('lunchChoices').doc(`${lerato}_${thisWeek}`),
    {
      childId: lerato,
      week: thisWeek,
      options: Object.fromEntries([
        options(lerato, '4_main', ['frikkadels', 'chicken-mayo', 'rice-salad']),
        options(lerato, '4_fruit', ['naartjie', 'apple', 'strawberries']),
      ]),
      chosen: {},
      editedDay: '4',
      updatedBy: mom,
      updatedAt: ctx.ago(5),
    },
  ]);
  docs.push([
    col('lunchChoices').doc(`${sipho}_${thisWeek}`),
    {
      childId: sipho,
      week: thisWeek,
      options: Object.fromEntries([options(sipho, '5_snack', ['popcorn', 'yoghurt'])]),
      chosen: { '5_snack': 'seed-popcorn' },
      chosenKey: '5_snack',
      editedDay: '5',
      updatedBy: mom,
      updatedAt: ctx.ago(4),
    },
  ]);

  await writeAll(ctx.store, docs);
  return `lunch: ${String(items.size)} library items, 4 week plans (2 children × 2 weeks), ${String(FAVOURITES.length)} go-to boxes, ${String(packedToday.length)} boxes packed, 2 kid-pick days`;
}
