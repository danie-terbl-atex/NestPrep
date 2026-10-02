/**
 * The canned answers the emulator's model gives *Plan my week*'s two steps
 * (lunch-box ADR-0012, foundation ADR-0015), keyed by each request's
 * `feature` label: `lunchIdeas` and `lunchWeek`. Both speak the Functions'
 * placeholders — `child-1`, `p-3` — so they fit any seeded household. A
 * placeholder the request did not have, a compartment already packed or a
 * product in the wrong compartment is dropped by the Function exactly as a
 * real answer's would be.
 *
 * The ideas suit the demo household on purpose, including two the Function
 * must strike out: peanut butter for Mia (peanut allergy, and Leo's nut-free
 * diet) and cherry tomatoes for Mia (a dislike).
 */
const BOTH = ['child-1', 'child-2'];

export const cannedLunchIdeasReply = {
  ideas: [
    {
      slot: 'main',
      idea: 'Cheese sandwiches',
      searchTerm: 'cheddar cheese slices',
      children: ['child-1'],
      why: 'child-1 likes cheese sandwiches',
    },
    {
      slot: 'main',
      idea: 'Wholewheat wraps',
      searchTerm: 'wholewheat wraps',
      children: BOTH,
      why: 'Easy to fill and keeps well',
    },
    {
      slot: 'main',
      idea: 'Pasta salad',
      searchTerm: 'fusilli pasta',
      children: ['child-2'],
      why: 'child-2 likes pasta',
    },
    {
      slot: 'main',
      idea: 'Peanut butter sandwiches',
      searchTerm: 'peanut butter',
      children: BOTH,
      why: 'A cheap staple',
    },
    {
      slot: 'fruit',
      idea: 'Apples',
      searchTerm: 'apples',
      children: BOTH,
      why: 'child-1 likes apples',
    },
    {
      slot: 'fruit',
      idea: 'Grapes',
      searchTerm: 'seedless grapes',
      children: ['child-2'],
      why: 'child-2 likes grapes',
    },
    {
      slot: 'fruit',
      idea: 'Bananas',
      searchTerm: 'bananas',
      children: BOTH,
      why: 'Cheap and filling',
    },
    {
      slot: 'veg',
      idea: 'Baby carrots',
      searchTerm: 'baby carrots',
      children: BOTH,
      why: 'Crunchy and ready to pack',
    },
    {
      slot: 'veg',
      idea: 'Cucumber sticks',
      searchTerm: 'english cucumber',
      children: BOTH,
      why: 'Mild and fresh',
    },
    {
      slot: 'veg',
      idea: 'Cherry tomatoes',
      searchTerm: 'cherry tomatoes',
      children: BOTH,
      why: 'Bite-sized',
    },
    {
      slot: 'snack',
      idea: 'Yoghurt tubs',
      searchTerm: 'yoghurt 6 pack',
      children: BOTH,
      why: 'Multi-pack stretches across the week',
    },
    {
      slot: 'snack',
      idea: 'Rice cakes',
      searchTerm: 'rice cakes',
      children: BOTH,
      why: 'Light and affordable',
    },
    {
      slot: 'treat',
      idea: 'Mini muffins',
      searchTerm: 'mini muffins',
      children: BOTH,
      why: 'A Friday treat',
    },
  ],
};

const DAYS = [1, 2, 3, 4, 5];
const SLOTS = ['main', 'fruit', 'veg', 'snack', 'treat'];
/** Products the canned week tries, per compartment, before the Function's check picks the first that fits. */
const TRIED_PER_COMPARTMENT = 7;

function lunchesFor(child, offset) {
  return DAYS.flatMap((day) =>
    SLOTS.filter((slot) => slot !== 'treat' || day === 5).flatMap((slot) =>
      Array.from({ length: TRIED_PER_COMPARTMENT }, (_, index) => ({
        child,
        day,
        slot,
        product: `p-${String(((day + offset + index) % 30) + 1)}`,
      })),
    ),
  );
}

export const cannedLunchWeekReply = {
  packs: Array.from({ length: 30 }, (_, index) => ({
    product: `p-${String(index + 1)}`,
    boxesPerPack: [1, 6, 8, 4][index % 4],
  })),
  lunches: [...lunchesFor('child-1', 0), ...lunchesFor('child-2', 3)],
};
