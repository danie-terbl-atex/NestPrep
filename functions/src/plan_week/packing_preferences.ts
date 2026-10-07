import { LUNCH_SLOTS, type LunchSlot } from './week_documents';

/**
 * How the parent wants to pack this week, chosen in step one of *Plan my
 * week*. The app's Dart enum holds the same names in the same order, and its
 * test reads this array literal to prove it — keep it on one line.
 */
// prettier-ignore
export const PACKING_PREFERENCES = ['readyMade', 'tenMinutes', 'airFryer', 'nightBefore', 'sundayBatch', 'favourPrice', 'singleServe', 'noFridge', 'healthier'] as const;
export type PackingPreference = (typeof PACKING_PREFERENCES)[number];

/** What the model reads for each preference the parent chose — food and effort words only. */
export const PACKING_INSTRUCTIONS: Readonly<Record<PackingPreference, string>> = {
  readyMade:
    'Prefer ready-made: favour ready-to-eat products that need no cooking or assembly — ready-made sandwiches and wraps, mini pies, cheese wedges or sticks, yoghurt tubs, fruit cups, cooked chicken strips, pre-cut veg. Avoid raw ingredients that need cooking or prep, such as raw chicken breasts, whole broccoli to steam or mince.',
  tenMinutes:
    'Ten minutes of prep at most: every box must be packable in about ten minutes in the morning. Nothing that needs real cooking and no raw meat; quick assembly such as buttering a roll or filling a wrap is fine.',
  airFryer:
    'Air fryer welcome: for mains, frozen items that need only 8 to 15 minutes in an air fryer are good — chicken nuggets, fish fingers, mini sausage rolls, potato wedges, samosas, spring rolls, crumbed chicken strips, mini pizzas.',
  nightBefore:
    'Prepped the night before: things made the evening before are fine — pasta salad, filled wraps, cut fruit — but nothing fiddly in the morning.',
  sundayBatch:
    'Sunday batch prep: welcome ingredients for things batch-made on Sunday and portioned for the week — muffins, frikkadels or meatballs, mini quiches, pasta bake.',
  favourPrice:
    "Favour price: choose the cheapest options that will do — house brands, multi-packs and promotions; generic terms such as the store's own house brand are fine to search. Between products, take the cheaper one and the one on promotion, and share one pack across children and days, even when no budget is given.",
  singleServe:
    'Single-serve packs: individually wrapped or portioned packs over big tubs and bags that need decanting.',
  noFridge:
    'No fridge needed: only food that stays safe unrefrigerated in a school bag until lunch; assume no ice pack.',
  healthier:
    'Healthier picks: wholegrain, less sugar and salt, more fruit and veg; keep treats small.',
};

/** The parent's step-one choices, as both callables receive them. */
export interface PackingChoices {
  readonly slots: readonly LunchSlot[];
  readonly preferences: readonly PackingPreference[];
}

/** What a phone that sends no choices gets: every compartment, no preference. */
export const NO_PACKING_CHOICES: PackingChoices = { slots: LUNCH_SLOTS, preferences: [] };

export function packingInstructions(preferences: readonly PackingPreference[]): string[] {
  return preferences.map((preference) => PACKING_INSTRUCTIONS[preference]);
}
