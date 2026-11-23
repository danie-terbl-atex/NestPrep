import { isFamilyRole } from '../household/access';

type Dimension = 'mass' | 'volume' | 'pack' | 'kitchen';

interface IngredientUnit {
  readonly code: string;
  readonly dimension: Dimension;
  readonly inBaseUnits: number;
}

const unit = (code: string, dimension: Dimension, inBaseUnits = 1): IngredientUnit => ({
  code,
  dimension,
  inBaseUnits,
});

const GRAM = unit('g', 'mass');
const KILOGRAM = unit('kg', 'mass', 1000);
const MILLILITRE = unit('ml', 'volume');
const LITRE = unit('l', 'volume', 1000);
const SPOONS = [unit('tsp', 'kitchen'), unit('tbsp', 'kitchen', 3), unit('cup', 'kitchen', 48)];
const UNITS: readonly IngredientUnit[] = [
  GRAM,
  KILOGRAM,
  MILLILITRE,
  LITRE,
  ...['pack', 'tin', 'loaf', 'bunch', 'bottle'].map((code) => unit(code, 'pack')),
  ...SPOONS,
];
const LEAST = [0, 1, 0.25];
const STEPS = [1, 0.5, 0.25];

const PLURALS: Readonly<Record<string, readonly [string, string]>> = {
  pack: ['pack', 'packs'],
  tin: ['tin', 'tins'],
  loaf: ['loaf', 'loaves'],
  bunch: ['bunch', 'bunches'],
  bottle: ['bottle', 'bottles'],
  cup: ['cup', 'cups'],
};

export const MIN_PEOPLE = 1;
export const MAX_PEOPLE = 24;

const MEAL_CONTEXTS = ['dinner', 'lunch', 'breakfast'] as const;

const PARTS = [0, 1 / 8, 1 / 4, 1 / 3, 1 / 2, 2 / 3, 3 / 4, 1] as const;
const FRACTIONS = [
  [1 / 8, '1/8'],
  [1 / 4, '1/4'],
  [1 / 3, '1/3'],
  [1 / 2, '1/2'],
  [2 / 3, '2/3'],
  [3 / 4, '3/4'],
] as const;
const WHOLE_FROM = 10;

export function kitchenRound(value: number): number {
  if (value >= WHOLE_FROM) return Math.round(value);
  const whole = Math.floor(value);
  const part = PARTS.reduce((best, next) =>
    Math.abs(value - whole - next) < Math.abs(value - whole - best) ? next : best,
  );
  const rounded = whole + part;
  return rounded > 0 ? rounded : PARTS[1];
}

function isMultipleOf(value: number, step: number): boolean {
  const steps = value / step;
  return Math.abs(steps - Math.round(steps)) < 0.02;
}

export function kitchenText(value: number): string {
  const whole = Math.floor(value);
  const part = value - whole;
  const fraction = FRACTIONS.find(([amount]) => Math.abs(amount - part) < 0.005)?.[1];
  if (fraction === undefined) return String(Math.round(value));
  return whole === 0 ? fraction : `${String(whole)} ${fraction}`;
}

export interface RecipeScale {
  readonly people: number;
  readonly servings: number;
}

export function recipeScale(people: number, servings: number): RecipeScale {
  return { people: Math.min(Math.max(people, MIN_PEOPLE), MAX_PEOPLE), servings };
}

export function startingPeopleFor(
  contexts: readonly string[],
  servings: number,
  familySize: number,
): number {
  const meal = MEAL_CONTEXTS.some((context) => contexts.includes(context));
  return meal && familySize > 0 ? familySize : servings;
}

export function familySizeOf(roles: readonly string[]): number {
  return roles.filter((role) => isFamilyRole(role) || role === 'kid').length;
}

export interface RecipeAmount {
  readonly value: number;
  readonly unit: IngredientUnit | null;
}

export function scaledAmount(
  quantity: number,
  unitCode: string | null,
  factor: number,
): RecipeAmount {
  const raw = quantity * factor;
  const measure = UNITS.find(({ code }) => code === unitCode) ?? null;
  switch (measure?.dimension) {
    case 'mass':
      return metric(raw * measure.inBaseUnits, GRAM, KILOGRAM);
    case 'volume':
      return metric(raw * measure.inBaseUnits, MILLILITRE, LITRE);
    case 'kitchen':
      return kitchen(raw, measure);
    default:
      return { value: count(raw), unit: measure };
  }
}

function metric(base: number, small: IngredientUnit, large: IngredientUnit): RecipeAmount {
  const rounded = base < 100 ? Math.max(1, Math.round(base)) : Math.round(base / 5) * 5;
  if (rounded < 1000) return { value: rounded, unit: small };
  return { value: (Math.round(base / 50) * 50) / 1000, unit: large };
}

function kitchen(amount: number, written: IngredientUnit): RecipeAmount {
  const teaspoons = amount * written.inBaseUnits;
  let index = SPOONS.indexOf(written);
  while (index > 0 && teaspoons / spoon(index).inBaseUnits < (LEAST[index] ?? 0)) index--;
  while (index < SPOONS.length - 1) {
    const larger = teaspoons / spoon(index + 1).inBaseUnits;
    if (larger < (LEAST[index + 1] ?? 0) || !isMultipleOf(larger, STEPS[index + 1] ?? 1)) break;
    index++;
  }
  const measure = spoon(index);
  return { value: kitchenRound(teaspoons / measure.inBaseUnits), unit: measure };
}

function spoon(index: number): IngredientUnit {
  return SPOONS[index] ?? GRAM;
}

function count(value: number): number {
  if (value >= 10) return Math.round(value);
  if (value >= 1) return Math.round(value * 2) / 2;
  return Math.max(0.25, Math.round(value * 4) / 4);
}

export function amountNumber(amount: RecipeAmount): string {
  switch (amount.unit?.code) {
    case 'kg':
    case 'l':
      return amount.value.toFixed(2).replace(/\.?0+$/, '');
    case 'g':
    case 'ml':
      return String(Math.round(amount.value));
    default:
      return kitchenText(amount.value);
  }
}

function unitWord(measure: IngredientUnit, value: number): string {
  const plural = PLURALS[measure.code];
  if (plural === undefined) return measure.code;
  return value <= 1 ? plural[0] : plural[1];
}

export interface ScalableLine {
  readonly name: string;
  readonly quantity: number | null;
  readonly unit?: string | null | undefined;
}

export interface ScaledLine {
  readonly name: string;
  readonly amount: RecipeAmount | null;
  readonly otherUnit: string | null;
}

export function scaleLine(line: ScalableLine, scale: RecipeScale): ScaledLine {
  const quantity = typeof line.quantity === 'number' && line.quantity > 0 ? line.quantity : null;
  const written = textOrNull(line.unit);
  const amount =
    quantity === null ? null : scaledAmount(quantity, written, scale.people / scale.servings);
  return {
    name: textOrNull(line.name) ?? '',
    amount,
    otherUnit: amount === null || amount.unit === null ? written : null,
  };
}

export function amountText(line: ScalableLine, scale: RecipeScale): string | null {
  const { amount, otherUnit } = scaleLine(line, scale);
  if (amount === null) return null;
  const word = amount.unit === null ? otherUnit : unitWord(amount.unit, amount.value);
  return [amountNumber(amount), ...(word === null ? [] : [word])].join(' ');
}

function textOrNull(value: string | null | undefined): string | null {
  const trimmed = value?.trim() ?? '';
  return trimmed === '' ? null : trimmed;
}
