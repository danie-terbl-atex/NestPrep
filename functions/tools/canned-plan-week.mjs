/**
 * The canned answer the emulator's model gives *Plan my week* (lunch-box
 * ADR-0011, foundation ADR-0015): a week in the placeholders the Function
 * sends — `child-1`, `main-2`, `meal-3` — so it fits any seeded household.
 * A placeholder that household does not have, or a compartment already
 * packed, is dropped by the Function exactly as a real answer's would be,
 * and the app tops up whatever is left from its own auto-fill.
 */
const DAYS = [1, 2, 3, 4, 5];

function lunchesFor(child) {
  return DAYS.flatMap((day) => [
    { child, day, slot: 'main', item: `main-${String(((day - 1) % 4) + 1)}` },
    { child, day, slot: 'fruit', item: `fruit-${String(((day + 1) % 4) + 1)}` },
    { child, day, slot: 'veg', item: `veg-${String(((day - 1) % 3) + 1)}` },
    { child, day, slot: 'snack', item: `snack-${String(((day + 2) % 4) + 1)}` },
    ...(day === 5 ? [{ child, day, slot: 'treat', item: 'treat-1' }] : []),
  ]);
}

export const cannedPlanWeekReply = {
  lunches: [...lunchesFor('child-1'), ...lunchesFor('child-2'), ...lunchesFor('child-3')],
  dinners: [
    { day: 1, meal: 'meal-1', newMeal: null },
    { day: 2, meal: 'meal-2', newMeal: null },
    {
      day: 3,
      meal: null,
      newMeal: {
        name: 'Chicken and vegetable tray bake',
        ingredients: [
          { name: 'Chicken thighs', quantity: '1 kg' },
          { name: 'Butternut', quantity: '1' },
          { name: 'Red onions', quantity: '2' },
          { name: 'Baby potatoes', quantity: '500 g' },
          { name: 'Olive oil', quantity: null },
        ],
      },
    },
    { day: 4, meal: 'meal-3', newMeal: null },
    { day: 5, meal: 'meal-4', newMeal: null },
    {
      day: 6,
      meal: null,
      newMeal: {
        name: 'Beef and bean chilli with rice',
        ingredients: [
          { name: 'Beef mince', quantity: '500 g' },
          { name: 'Kidney beans', quantity: '1 tin' },
          { name: 'Chopped tomatoes', quantity: '1 tin' },
          { name: 'Rice', quantity: '500 g' },
        ],
      },
    },
    { day: 7, meal: 'meal-5', newMeal: null },
  ],
};
