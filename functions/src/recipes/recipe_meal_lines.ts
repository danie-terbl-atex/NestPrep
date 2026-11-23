import { type RecipeScale, type ScalableLine, scaleLine } from './recipe_scale';

export const MEAL_LINE_LIMIT = 40;
export const MEAL_LINE_NAME_LIMIT = 60;

export interface MealLine {
  readonly name: string;
  readonly amount: number | null;
  readonly unit: string | null;
}

export function recipeMealLines(lines: readonly ScalableLine[], scale: RecipeScale): MealLine[] {
  return lines.slice(0, MEAL_LINE_LIMIT).map((line) => {
    const scaled = scaleLine(line, scale);
    const amount = scaled.otherUnit === null ? scaled.amount : null;
    return {
      name: scaled.name.substring(0, MEAL_LINE_NAME_LIMIT).trim(),
      amount: amount?.value ?? null,
      unit: amount === null ? null : (amount.unit?.code ?? null),
    };
  });
}
