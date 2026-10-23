import { mayReadGroceries } from '../cart_push/grocery_reader';
import { refuseCheckers } from './errors';

/**
 * Refuses unless the caller may see the household's grocery list (household
 * ADR-0003). Pure over the household data, so it is tested without an emulator.
 */
export function requireGroceryReader(householdData: unknown, uid: string): void {
  if (!mayReadGroceries(householdData, uid)) throw refuseCheckers('not-a-member');
}
