import { hash } from 'node:crypto';

import { FieldValue, type DocumentReference, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { isFeatureOn } from '../ai/ai_settings';
import { allowanceStanding, type AllowanceStanding } from '../ai/firestore_usage_ledger';
import { NO_USAGE } from '../ai/generative_model';
import { callForImage, IMAGE_CALL_LIMITS } from '../ai/image_call';
import type { ImageReply, ImageRequest } from '../ai/image_model';
import {
  runAiCall,
  spendAiCall,
  type AiDependencies,
  type ImageDependencies,
} from '../ai/run_ai_call';
import { StructuredCallFailure, realClock, type StructuredReply } from '../ai/structured_call';
import { CALLS_PER_CREATION } from '../ai/usage_rules';
import { todayIn } from '../documents/expiry_schedule';
import { framePhotosPrefix } from '../frames/frame_documents';
import { memberColorHex } from '../frames/member_colors';
import { isFamilyRole } from '../household/access';
import { householdRef, memberRef } from '../household/documents';
import { deliverAvatarReady } from '../notifications/avatar_delivery';
import type { PushSender } from '../notifications/push_sender';
import type { ObjectStore } from '../shared/storage';
import { hemisphereOf } from './avatar_moments';
import { portraitScene, portraitSitting } from './avatar_portrait';
import {
  AVATAR_STYLES,
  type AvatarStyle,
  type ReferenceKind,
  type ReferenceReading,
  buddyWords,
  extraCheck,
  extraReading,
  forPortrait,
  fromBuddy,
  fromDrawing,
  fromPet,
  fromWords,
  referenceCheck,
  referenceReading,
  resultCheck,
  resultIsClean,
  resultReading,
} from './avatar_prompts';
import {
  AVATAR_INBOX_MAX_BYTES,
  AVATAR_MADE_MAX_BYTES,
  avatarCreationRef,
  avatarImagePath,
  avatarInboxPath,
  avatarKeepsakePath,
  avatarKeepsakeRef,
  memberAvatarRef,
} from './avatar_refs';

export const CREATION_RECIPES = ['drawing', 'buddy', 'pet', 'portrait'] as const;
export type CreationRecipe = (typeof CREATION_RECIPES)[number];

export type CreationRefusal =
  'notAllowed' | 'creationsOff' | 'limitReached' | 'premiumRequired' | 'declined';

export type CreationOutcome =
  | { readonly status: 'ready'; readonly imageHash: string; readonly left: number }
  | { readonly status: 'refused'; readonly reason: CreationRefusal; readonly left?: number }
  | { readonly status: 'failed'; readonly reason: 'unavailable'; readonly left?: number };

const word = z.string().regex(/^[a-z0-9-]{1,48}$/);

const storedCreation = z.object({
  memberId: z.string().min(1),
  recipe: z.enum(CREATION_RECIPES),
  style: z.enum(AVATAR_STYLES).optional(),
  buddy: z
    .object({ creature: word, colour: word, loves: word, wears: word, power: word })
    .optional(),
  extra: z.string().max(60).optional(),
  inboxId: z
    .string()
    .regex(/^[A-Za-z0-9_-]{8,64}$/)
    .optional(),
  requestedBy: z.string().min(1),
});
type StoredCreation = z.infer<typeof storedCreation>;

export interface CreationFacts {
  readonly flagOn: boolean;
  readonly aiOn: boolean;
  readonly creationsOn: boolean;
  readonly memberExists: boolean;
  readonly requesterIsFamily: boolean;
  readonly recipe: CreationRecipe;
  readonly hasReference: boolean;
  readonly buddyKnown: boolean;
  readonly standing: AllowanceStanding | null;
}

/** The first reason a request may not be drawn, checked before anything is spent. */
export function gateCreation(facts: CreationFacts): CreationRefusal | 'unavailable' | null {
  if (!facts.flagOn || !facts.aiOn || facts.standing === null) return 'unavailable';
  if (!facts.memberExists) return 'notAllowed';
  if (!facts.creationsOn) return 'creationsOff';
  if (facts.recipe === 'portrait' && !facts.requesterIsFamily) return 'notAllowed';
  if ((facts.recipe === 'drawing' || facts.recipe === 'pet') && !facts.hasReference) {
    return 'notAllowed';
  }
  if (facts.recipe === 'buddy' && !facts.buddyKnown) return 'notAllowed';
  if (facts.standing.tier === 'free') return 'premiumRequired';
  if (facts.standing.left <= 0) return 'limitReached';
  if (facts.standing.attemptsLeft < CALLS_PER_CREATION) return 'limitReached';
  return null;
}

export type ReferencePath = 'reference' | 'words' | 'refuse';

/**
 * What a read reference becomes. A drawing of a person is never sent to the
 * image model, only words about its colours (the lesson on `ALLOW_NONE`).
 */
export function referencePath(recipe: 'drawing' | 'pet', kind: ReferenceKind): ReferencePath {
  if (recipe === 'pet') return kind === 'photo-of-pet' ? 'reference' : 'refuse';
  if (kind === 'drawing-of-person') return 'words';
  return ['drawing-of-creature', 'drawing-of-object', 'photo-of-toy', 'photo-of-pet'].includes(kind)
    ? 'reference'
    : 'refuse';
}

export function referencePicture(
  recipe: 'drawing' | 'pet',
  style: AvatarStyle,
  fill: string,
  reference: Buffer,
  reading: ReferenceReading,
): ImageRequest | 'refuse' {
  const path = referencePath(recipe, reading.kind);
  if (path === 'refuse') return 'refuse';
  if (path === 'words') return fromWords(style, fill, reading);
  return recipe === 'pet' ? fromPet(style, fill, reference) : fromDrawing(style, fill, reference);
}

export function refusalFor(reason: string, tier: 'free' | 'premium' | undefined): CreationOutcome {
  if (reason === 'aiDeclined') return { status: 'refused', reason: 'declined' };
  if (reason === 'aiLimitReached') {
    return {
      status: 'refused',
      reason: tier === 'premium' ? 'limitReached' : 'premiumRequired',
      left: 0,
    };
  }
  return { status: 'failed', reason: 'unavailable' };
}

export function imageHashOf(bytes: Buffer): string {
  return hash('sha256', bytes, 'hex').slice(0, 32);
}

export function memberFill(colour: unknown): string {
  const name = typeof colour === 'string' ? colour : undefined;
  const hex = memberColorHex(name);
  return hex === null ? 'cream #F6EFE3' : `${name ?? ''} ${hex}`;
}

export function portraitPhotoId(creationId: string): string {
  return `portrait-${creationId}`;
}

export interface CreationDeps {
  readonly store: Firestore;
  readonly objects: ObjectStore;
  readonly sender: PushSender;
  readonly text: AiDependencies;
  readonly image: ImageDependencies;
  readonly flagOn: boolean;
  readonly now: Date;
  readonly imageTurn?: () => Promise<void>;
}

interface Begun {
  readonly ref: DocumentReference;
  readonly householdId: string;
  readonly creationId: string;
  readonly request: StoredCreation;
  readonly timeZone: string;
  readonly creationsOn: boolean;
  readonly memberExists: boolean;
  readonly memberColour: unknown;
  readonly requesterIsFamily: boolean;
  readonly requesterUid: string;
}

const storedHousehold = z.object({
  timeZone: z.string().catch('UTC'),
  members: z.record(z.string(), z.string()).catch({}),
  kids: z.record(z.string(), z.string()).catch({}),
  avatarCreationsOn: z.unknown().optional(),
});

async function begin(
  store: Firestore,
  householdId: string,
  creationId: string,
): Promise<Begun | 'gone' | 'alreadySettled' | 'malformed'> {
  const ref = avatarCreationRef(store, householdId, creationId);
  return store.runTransaction(async (transaction) => {
    const creation = await transaction.get(ref);
    if (!creation.exists) return 'gone';
    if (creation.get('status') !== undefined) return 'alreadySettled';
    const parsed = storedCreation.safeParse(creation.data());
    if (!parsed.success) {
      transaction.update(ref, {
        status: 'refused',
        reason: 'notAllowed',
        settledAt: FieldValue.serverTimestamp(),
      });
      return 'malformed';
    }
    const request = parsed.data;
    const [home, member, requester] = await transaction.getAll(
      householdRef(store, householdId),
      memberRef(store, householdId, request.memberId),
      memberRef(store, householdId, request.requestedBy),
    );
    const household = storedHousehold.parse(home?.data() ?? {});
    const claimedBy: unknown = requester?.get('claimedBy');
    const accountRole = typeof claimedBy === 'string' ? household.members[claimedBy] : undefined;
    const kidDevice = Object.entries(household.kids).find(([, id]) => id === request.requestedBy);
    transaction.update(ref, { status: 'checking' });
    return {
      ref,
      householdId,
      creationId,
      request,
      timeZone: household.timeZone,
      creationsOn: home?.exists === true && household.avatarCreationsOn !== false,
      memberExists: member?.exists === true,
      memberColour: member?.get('color') as unknown,
      requesterIsFamily: accountRole !== undefined && isFamilyRole(accountRole),
      requesterUid:
        accountRole !== undefined && typeof claimedBy === 'string'
          ? claimedBy
          : (kidDevice?.[0] ?? request.requestedBy),
    };
  });
}

/**
 * One `avatarCreations` request, from `checking` to `ready`, `refused` or
 * `failed` (avatars ADR-0003, ADR-0005, ADR-0006). Only the run that moves it
 * out of no status does anything, so a repeated event never draws or charges
 * twice; the allowance is claimed with the picture and refunded with it.
 */
export async function settleAvatarCreation(
  deps: CreationDeps,
  householdId: string,
  creationId: string,
): Promise<CreationOutcome | 'gone' | 'alreadySettled' | 'malformed'> {
  const begun = await begin(deps.store, householdId, creationId);
  if (typeof begun === 'string') return begun;
  let outcome: CreationOutcome;
  try {
    outcome = await make(deps, begun);
  } catch (error) {
    logger.error('avatar creation broke', {
      householdId,
      error: error instanceof Error ? error.name : 'unknown',
    });
    outcome = { status: 'failed', reason: 'unavailable' };
  }
  try {
    await finish(deps, begun, outcome);
  } finally {
    const { memberId, inboxId } = begun.request;
    if (inboxId !== undefined) {
      await deps.objects.deleteObjects([avatarInboxPath(householdId, memberId, inboxId)]);
    }
  }
  return outcome;
}

async function make(deps: CreationDeps, begun: Begun): Promise<CreationOutcome> {
  const { request } = begun;
  const feature = request.recipe === 'portrait' ? 'avatarPortrait' : 'avatarCreate';
  const standing = await allowanceStanding(deps.store, {
    householdId: begun.householdId,
    timeZone: begun.timeZone,
    feature,
    now: deps.now,
    settings: deps.image.settings,
  });
  const inbox =
    request.inboxId === undefined
      ? null
      : await deps.objects.read(
          avatarInboxPath(begun.householdId, request.memberId, request.inboxId),
          'image/jpeg',
          AVATAR_INBOX_MAX_BYTES,
        );
  const words = request.buddy === undefined ? null : buddyWords(request.buddy);
  const gate = gateCreation({
    flagOn: deps.flagOn,
    aiOn:
      isFeatureOn(deps.image.settings, feature) && isFeatureOn(deps.text.settings, 'avatarCheck'),
    creationsOn: begun.creationsOn,
    memberExists: begun.memberExists,
    requesterIsFamily: begun.requesterIsFamily,
    recipe: request.recipe,
    hasReference: inbox !== null,
    buddyKnown: words !== null,
    standing,
  });
  const left = standing?.left;
  if (gate === 'unavailable') return { status: 'failed', reason: 'unavailable', ...withLeft(left) };
  if (gate !== null) return { status: 'refused', reason: gate, ...withLeft(left) };

  const spend = {
    householdId: begun.householdId,
    timeZone: begun.timeZone,
    uid: begun.requesterUid,
  };
  const style: AvatarStyle = request.style ?? 'plush';
  const fill = memberFill(begun.memberColour);

  let picture: ImageRequest;
  try {
    const planned = await plan(deps, begun, { inbox, words, style, fill, spend });
    if (planned === 'refuse') return { status: 'refused', reason: 'notAllowed', ...withLeft(left) };
    picture = planned;
  } catch (error) {
    return { ...refusalFor(refusalReason(error) ?? 'error', standing?.tier), ...withLeft(left) };
  }

  await moveTo(deps.store, begun.ref, 'checking', { status: 'drawing' });
  try {
    const drawn = await spendAiCall(deps.image, { ...spend, feature }, deps.image.model.name, () =>
      drawAndKeep(deps, begun, picture, inbox),
    );
    return { status: 'ready', imageHash: imageHashOf(drawn.value.bytes), left: drawn.callsLeft };
  } catch (error) {
    const reason = refusalReason(error);
    if (reason === undefined) throw error;
    const refused = refusalFor(reason, standing?.tier);
    return refused.left === undefined ? { ...refused, ...withLeft(left) } : refused;
  }
}

function withLeft(left: number | undefined): { left?: number } {
  return left === undefined ? {} : { left };
}

interface Ingredients {
  readonly inbox: Buffer | null;
  readonly words: ReturnType<typeof buddyWords>;
  readonly style: AvatarStyle;
  readonly fill: string;
  readonly spend: { householdId: string; timeZone: string; uid: string };
}

async function plan(
  deps: CreationDeps,
  begun: Begun,
  ingredients: Ingredients,
): Promise<ImageRequest | 'refuse'> {
  const { request } = begun;
  const { inbox, words, style, fill, spend } = ingredients;
  const check = { ...spend, feature: 'avatarCheck' as const };
  switch (request.recipe) {
    case 'drawing':
    case 'pet': {
      if (inbox === null) return 'refuse';
      const reading = await runAiCall(deps.text, {
        ...check,
        request: referenceCheck(request.recipe, inbox),
        schema: referenceReading,
      });
      return referencePicture(request.recipe, style, fill, inbox, reading.value);
    }
    case 'buddy': {
      if (words === null) return 'refuse';
      const extra = request.extra?.trim() ?? '';
      if (extra !== '') {
        const verdict = await runAiCall(deps.text, {
          ...check,
          request: extraCheck(extra),
          schema: extraReading,
        });
        if (!verdict.value.allowed) return 'refuse';
      }
      return fromBuddy(style, fill, words, extra === '' ? null : extra);
    }
    case 'portrait': {
      const sitting = await portraitSitting(deps.store, deps.objects, begun.householdId);
      if (sitting.references.length === 0) return 'refuse';
      const today = todayIn(begun.timeZone, deps.now);
      return forPortrait(
        sitting.references,
        portraitScene(today, hemisphereOf(begun.timeZone), sitting.birthdays),
      );
    }
  }
}

async function drawAndKeep(
  deps: CreationDeps,
  begun: Begun,
  picture: ImageRequest,
  inbox: Buffer | null,
): Promise<StructuredReply<ImageReply>> {
  await deps.imageTurn?.();
  const drawn = await callForImage(
    deps.image.model,
    picture,
    deps.image.limits ?? IMAGE_CALL_LIMITS,
    deps.image.clock ?? realClock,
  );
  const { bytes, mimeType } = drawn.value;
  if (mimeType !== 'image/jpeg' || bytes.length === 0 || bytes.length > AVATAR_MADE_MAX_BYTES) {
    throw new StructuredCallFailure(
      'unavailable',
      `picture unusable: ${mimeType}`,
      NO_USAGE,
      drawn.attempts,
    );
  }
  const verdict = await asCallFailure(() =>
    runAiCall(deps.text, {
      householdId: begun.householdId,
      timeZone: begun.timeZone,
      uid: begun.requesterUid,
      feature: 'avatarCheck',
      request: resultCheck(bytes),
      schema: resultReading,
    }),
  );
  if (!resultIsClean(verdict.value)) {
    throw new StructuredCallFailure('declined', 'result check', NO_USAGE, drawn.attempts);
  }
  await keep(deps, begun, bytes, inbox);
  return drawn;
}

async function asCallFailure<T>(call: () => Promise<T>): Promise<T> {
  try {
    return await call();
  } catch (error) {
    const reason = refusalReason(error);
    if (reason === undefined) throw error;
    throw new StructuredCallFailure(
      reason === 'aiDeclined' ? 'declined' : 'unavailable',
      `result check: ${reason}`,
      NO_USAGE,
      0,
    );
  }
}

function refusalReason(error: unknown): string | undefined {
  if (!(error instanceof HttpsError)) return undefined;
  const details: unknown = error.details;
  return typeof details === 'object' && details !== null && 'reason' in details
    ? String(details.reason)
    : undefined;
}

/**
 * The picture is stored and owned, the original moved beside it as a
 * keepsake, in one transaction with the keepsake document; a failure takes
 * back the files it put up.
 */
async function keep(
  deps: CreationDeps,
  begun: Begun,
  bytes: Buffer,
  inbox: Buffer | null,
): Promise<void> {
  const { store, objects } = deps;
  const { householdId, creationId, request } = begun;
  const portrait = request.recipe === 'portrait';
  const owner = portrait ? request.requestedBy : request.memberId;
  const imageHash = imageHashOf(bytes);
  const imagePath = avatarImagePath(householdId, owner, imageHash);
  const originalPath =
    inbox === null ? null : avatarKeepsakePath(householdId, request.memberId, creationId);
  const albumPath = portrait
    ? `${framePhotosPrefix(householdId)}${portraitPhotoId(creationId)}`
    : null;
  const put: string[] = [];
  try {
    await objects.save(imagePath, bytes, 'image/jpeg');
    put.push(imagePath);
    if (originalPath !== null && inbox !== null) {
      await objects.save(originalPath, inbox, 'image/jpeg');
      put.push(originalPath);
    }
    if (albumPath !== null) {
      await objects.save(albumPath, bytes, 'image/jpeg', undefined, {
        uploadedByUid: begun.requesterUid,
      });
      put.push(albumPath);
    }
    await store.runTransaction(async (transaction) => {
      const keepsakeRef = avatarKeepsakeRef(store, householdId, creationId);
      const [creation, kept, member] = await transaction.getAll(
        begun.ref,
        keepsakeRef,
        memberRef(store, householdId, owner),
      );
      if (creation?.get('status') !== 'drawing') throw new Error('creation moved on');
      if (member?.exists !== true) throw new Error('member gone');
      if (kept?.exists !== true) {
        transaction.create(keepsakeRef, {
          memberId: owner,
          recipe: request.recipe,
          style: portrait ? null : (request.style ?? 'plush'),
          originalPath,
          ...(request.buddy === undefined ? {} : { buddy: request.buddy }),
          imageHash,
          createdAt: FieldValue.serverTimestamp(),
          createdBy: request.requestedBy,
        });
      }
      if (!portrait) {
        transaction.set(
          memberAvatarRef(store, householdId, owner),
          { owned: { images: FieldValue.arrayUnion(imageHash) } },
          { merge: true },
        );
      }
      transaction.update(begun.ref, { imageHash, keepsakeId: creationId });
    });
  } catch (error) {
    await objects.deleteObjects(put);
    throw error;
  }
}

async function moveTo(
  store: Firestore,
  ref: DocumentReference,
  from: string,
  fields: Record<string, unknown>,
): Promise<boolean> {
  return store.runTransaction(async (transaction) => {
    if ((await transaction.get(ref)).get('status') !== from) return false;
    transaction.update(ref, fields);
    return true;
  });
}

async function finish(deps: CreationDeps, begun: Begun, outcome: CreationOutcome): Promise<void> {
  const { request } = begun;
  const settled = await deps.store.runTransaction(async (transaction) => {
    const status: unknown = (await transaction.get(begun.ref)).get('status');
    if (status !== 'checking' && status !== 'drawing') return false;
    transaction.update(begun.ref, {
      status: outcome.status,
      ...(outcome.status === 'ready' ? {} : { reason: outcome.reason }),
      ...(outcome.left === undefined ? {} : { left: outcome.left }),
      settledAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  logger.info('avatar creation settled', {
    householdId: begun.householdId,
    recipe: request.recipe,
    status: outcome.status,
    reason: outcome.status === 'ready' ? null : outcome.reason,
  });
  if (settled && outcome.status === 'ready') {
    await deliverAvatarReady(deps.store, deps.sender, {
      householdId: begun.householdId,
      creationId: begun.creationId,
      requestedBy: request.requestedBy,
      portrait: request.recipe === 'portrait',
      now: deps.now,
    });
  }
}
