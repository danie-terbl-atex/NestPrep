import type { Area } from '../household/access';

/**
 * What a member lets an assistant do, chosen on the consent page (assistants
 * ADR-0003). Each scope maps to one household area and the level the member
 * must still hold there when the call is made, so a connection never does more
 * than its member could in the app. Medical, documents, family-profile detail,
 * the nanny hub, home care and co-parenting have no scope on purpose.
 */
export const ASSISTANT_SCOPES = [
  'household:read',
  'calendar:read',
  'calendar:write',
  'lists:read',
  'lists:write',
] as const;
export type AssistantScope = (typeof ASSISTANT_SCOPES)[number];

export interface ScopeNeed {
  readonly area: Area | null;
  readonly level: 'view' | 'edit';
}

export const SCOPE_NEEDS: Record<AssistantScope, ScopeNeed> = {
  'household:read': { area: null, level: 'view' },
  'calendar:read': { area: 'calendar', level: 'view' },
  'calendar:write': { area: 'calendar', level: 'edit' },
  'lists:read': { area: 'groceries', level: 'view' },
  'lists:write': { area: 'groceries', level: 'edit' },
};

export function isAssistantScope(value: string): value is AssistantScope {
  return (ASSISTANT_SCOPES as readonly string[]).includes(value);
}

/** The scopes in a space-separated OAuth `scope` string, unknown ones dropped. */
export function parseScopes(scope: string | undefined): AssistantScope[] {
  if (scope === undefined) return [];
  const wanted = new Set(scope.split(' ').filter(isAssistantScope));
  return ASSISTANT_SCOPES.filter((known) => wanted.has(known));
}
