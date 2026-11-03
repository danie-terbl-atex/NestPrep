import { listed, type ListedTool } from '../tool';
import { deleteEvent, updateEvent } from './change_event';
import { createEvent } from './create_event';
import { getHousehold } from './get_household';
import {
  addGroceryItems,
  getGroceryList,
  removeGroceryItems,
  tickGroceryItems,
  updateGroceryItem,
} from './groceries';
import { listEvents } from './list_events';

/**
 * The v1 tools (assistants ADR-0001), in the fixed order `tools/list`
 * answers with so a host's cache and prompt stay stable. Names are a contract
 * with members' saved prompts: add, never rename.
 */
export const ASSISTANT_TOOLS: readonly ListedTool[] = [
  listed(getHousehold),
  listed(listEvents),
  listed(createEvent),
  listed(updateEvent),
  listed(deleteEvent),
  listed(getGroceryList),
  listed(addGroceryItems),
  listed(updateGroceryItem),
  listed(tickGroceryItems),
  listed(removeGroceryItems),
];

export function toolNamed(name: string): ListedTool | undefined {
  return ASSISTANT_TOOLS.find((tool) => tool.name === name);
}
