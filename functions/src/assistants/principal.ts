import type { AssistantScope } from './assistant_scopes';

/** Which assistant a connection belongs to, from its verified client host. */
export const ASSISTANT_VIAS = ['claude', 'chatgpt', 'assistant'] as const;
export type AssistantVia = (typeof ASSISTANT_VIAS)[number];

/**
 * Who an assistant call acts as: one member of one household through one
 * connection (assistants ADR-0003). Built from a bearer token on every call
 * and never cached, because the grant behind it can be revoked at any moment.
 */
export interface AssistantPrincipal {
  readonly grantId: string;
  readonly uid: string;
  readonly householdId: string;
  readonly via: AssistantVia;
  readonly scopes: readonly AssistantScope[];
}

/** Turns an `Authorization` header into a principal, or throws an [AssistantRefusal]. */
export type Authenticate = (
  authorization: string | undefined,
  now: Date,
) => Promise<AssistantPrincipal>;

/**
 * Every way an assistant call is refused. `invalidToken` and
 * `insufficientScope` become the HTTP 401 and 403 challenges the MCP spec
 * defines, so the assistant can sign in again or ask for more; the rest become
 * a tool error the assistant can explain.
 */
export type AssistantRefusalKind =
  | 'invalidToken'
  | 'insufficientScope'
  | 'forbidden'
  | 'notFound'
  | 'badRequest'
  | 'conflict'
  | 'rateLimited'
  | 'switchedOff';

export class AssistantRefusal extends Error {
  constructor(
    readonly kind: AssistantRefusalKind,
    readonly reason: string,
    message: string,
    readonly scope?: AssistantScope,
  ) {
    super(message);
    this.name = 'AssistantRefusal';
  }
}
