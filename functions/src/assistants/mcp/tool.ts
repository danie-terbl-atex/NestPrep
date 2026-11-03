import type { Firestore } from 'firebase-admin/firestore';
import type { z } from 'zod';

import type { AssistantScope } from '../assistant_scopes';
import type { AssistantPrincipal } from '../principal';

/**
 * What the host shows before a call and what it may assume (assistants
 * ADR-0001). Every hint is an explicit boolean, and nothing reaches outside
 * NestPrep, so `openWorldHint` is always false.
 */
export interface ToolAnnotations {
  readonly readOnlyHint: boolean;
  readonly destructiveHint: boolean;
  readonly idempotentHint: boolean;
  readonly openWorldHint: false;
}

/**
 * One assistant tool (assistants ADR-0001): the scope it needs, the hints and
 * schemas a host reads, and its body. The body is a plain function of the
 * store, the principal, the parsed input and the clock — it makes the
 * `requireAccess` check itself — so each one is tested against the emulator
 * without HTTP in front of it.
 */
export interface AssistantTool<Input extends z.ZodObject, Output extends z.ZodObject> {
  readonly name: string;
  readonly title: string;
  readonly description: string;
  readonly scope: AssistantScope;
  readonly annotations: ToolAnnotations;
  readonly input: Input;
  readonly output: Output;
  readonly run: (
    store: Firestore,
    principal: AssistantPrincipal,
    input: z.output<Input>,
    now: Date,
  ) => Promise<z.input<Output>>;
}

/** A tool with its types erased, as the server's table holds it. */
export interface ListedTool {
  readonly name: string;
  readonly title: string;
  readonly description: string;
  readonly scope: AssistantScope;
  readonly annotations: ToolAnnotations;
  readonly input: z.ZodObject;
  readonly output: z.ZodObject;
  readonly call: (
    store: Firestore,
    principal: AssistantPrincipal,
    args: unknown,
    now: Date,
  ) => Promise<Record<string, unknown>>;
}

/**
 * Erases a tool's types for the table. The arguments are parsed again here,
 * so the body never sees anything its own schema did not produce, whoever
 * calls it.
 */
export function listed<Input extends z.ZodObject, Output extends z.ZodObject>(
  tool: AssistantTool<Input, Output>,
): ListedTool {
  return {
    name: tool.name,
    title: tool.title,
    description: tool.description,
    scope: tool.scope,
    annotations: tool.annotations,
    input: tool.input,
    output: tool.output,
    call: async (store, principal, args, now) =>
      tool.output.parse(await tool.run(store, principal, tool.input.parse(args), now)),
  };
}
