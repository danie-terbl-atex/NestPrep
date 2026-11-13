# Avatars — the shared build spec (all agents build against this)

Decisions: Godfather `avatars` feature, ADR-0001…0006 (read them with `mcp__godfather__read_doc`; ids below).
Plan: `~/.claude/plans/fizzy-snacking-pearl.md`. Lesson on the image filter: Godfather "With personGeneration ALLOW_NONE…".
Daniel approved everything 2026-11-12: premium 12 creations/month, free 1 ever; **no parent approval**; art from our pipeline.
If something here is wrong when you meet the code, follow the code's conventions, note the deviation in your report.

## Names (exact strings, shared by Dart, TS, Kotlin, rules)

| Thing | Value |
|---|---|
| Flags (`appConfig/flags`) | `avatars` (phases 1–3), `avatarCreations` (phases 4–5) |
| AI features (`appConfig/ai.features`) | `avatarCheck`, `avatarCreate`, `avatarPortrait` |
| PremiumFeature / CONVERSION_TRIGGERS | `avatarCreate`, `avatarPortrait` |
| Collections under `households/{h}/` | `memberAvatars/{memberId}`, `avatarPurchases/{id}`, `avatarCreations/{id}`, `avatarKeepsakes/{id}` |
| Storage | `households/{h}/avatars/{memberId}/{hash}.jpg` · `…/inbox/{id}.jpg` · `…/keepsakes/{id}.jpg` |
| Image hash | first 32 hex chars of sha256(bytes), lowercase: `^[0-9a-f]{32}$` |
| Asset ids | `^[a-z0-9-]{1,48}$`: Nestlings `nestling-<name>-<stage>` (stage 0–3), accessories `acc-<name>`, moments `moment-<name>` |
| Slots | `top`, `badge`, `ring`, `face` (`face` on Nestling bases only) |
| Stages | 0 egg · 1 hatchling · 2 fledgling · 3 flyer |
| Styles | `plush`, `clay`, `knitted`, `wooden`, `vinyl`, `sticker` |
| Recipes | `drawing`, `buddy`, `pet`, `portrait` |

## The catalogue (one source: `tools/avatar-pictures/catalogue.json`)

```json
{
  "nestlings":   [{"id": "pip", "name": "Pip", "subject": "…"}],
  "accessories": [{"id": "crown", "label": "Crown", "slot": "top", "stars": 20, "subject": "…"}],
  "moments":     [{"id": "birthday-hat", "label": "Birthday hat", "slot": "top", "rule": {"kind": "birthday"}, "subject": "…"}],
  "buddy": {"creature": [{"id": "dragon", "label": "Dragon"}], "colour": […], "loves": […], "wears": […], "power": […]}
}
```

- `stars: 0` = free accessory, worn by anyone. A priced accessory must be owned.
- Moment rules: `{"kind":"birthday"}` · `{"kind":"dates","from":"MM-DD","to":"MM-DD"}` (inclusive, may wrap the year) · `{"kind":"easter","from":-2,"to":1}` (days around Western Easter Sunday) · `{"kind":"dates","from":…,"to":…,"hemisphere":"south"|"north"}`. Hemisphere from the household's IANA zone (Africa/Johannesburg, Australia/*, Pacific/Auckland, America/Sao_Paulo… south; everything else north).
- **Which moment shows:** a birthday moment always takes its slot; otherwise the first active moment in catalogue order fills a slot **only if nothing is worn there**. At most one moment per slot.
- Generated API (the art agent writes these first, before any picture, so other agents can import them):
  - TS `functions/src/avatars/avatar_catalogue.ts`: `export const NESTLINGS: readonly { name: string; label: string }[]`; `export const ACCESSORIES: readonly { id: string; label: string; slot: AvatarSlot; stars: number }[]`; `export const MOMENTS: readonly { id: string; label: string; slot: AvatarSlot; rule: MomentRule }[]`; `export const BUDDY: Readonly<Record<'creature'|'colour'|'loves'|'wears'|'power', readonly { id: string; label: string }[]>>`; `export type AvatarSlot = 'top'|'badge'|'ring'|'face'`; `export type MomentRule = {kind:'birthday'} | {kind:'dates'; from: string; to: string; hemisphere?: 'south'|'north'} | {kind:'easter'; from: number; to: number}`; `export function nestlingAssetId(name: string, stage: number): string`.
  - Dart `app/lib/features/avatars/model/avatar_catalogue.g.dart`: the same lists as `const` (`avatarNestlings`, `avatarAccessories`, `avatarMoments`, `avatarBuddy`) of plain classes `AvatarNestling{name,label}`, `AvatarAccessory{id,label,slot,stars}`, `AvatarMoment{id,label,slot,rule}`, `AvatarChoiceWord{id,label}`, enum `AvatarSlot {top, badge, ring, face}`, sealed `MomentRule`, and `String nestlingAssetId(String name, int stage)` and `String avatarAssetPath(String assetId)` → `assets/avatars/<id>.webp`.
- **Face anchors (decided 2026-11-12 night, after the art landed):** eyes sit at different heights per Nestling picture, so every Nestling asset carries `face: {x, y, w}` in the catalogue (normalised 0–1 on the 384 square: centre between the eyes, and the eye span), measured once and reviewed on a sheet. Generated as TS `NESTLING_FACES: Readonly<Record<string, {x: number; y: number; w: number}>>` (keyed by asset id), Dart `const Map<String, AvatarFace> avatarNestlingFaces` (`AvatarFace{x,y,w}`), and for the frame `../NestPrep-Home/app/src/main/java/io/nullstate/nestprep/home/AvatarFaces.kt` (generated, `object AvatarFaces { fun of(assetId: String): Face? }`). A `face` accessory is drawn centred on (x, y) at width `w * 1.6` of the base's drawn size; a base with no anchor draws no face layer.
- `tools/avatar-pictures/build.py` generates from it: `app/lib/features/avatars/model/avatar_catalogue.g.dart`, `functions/src/avatars/avatar_catalogue.ts`, and copies assets to `app/assets/avatars/<asset id>.webp` (384 px) and `../NestPrep-Home/app/src/main/assets/avatars/<asset id>.webp` (128 px), plus `functions/assets/avatars/<asset id>.webp` (384 px, for the portrait). Generated files are committed; never edit them by hand.

## Data

`households/{h}/memberAvatars/{memberId}` — the choice (ADR-0001)
```
choice:       { base: 'initial' | 'preset:<nestling name>' | 'image:<hash>', stage?: 0..3, wear: { top?, badge?, ring?, face? } }   // wear values are accessory ids `acc-…`
pendingPhoto: <hash> | absent           // a photo the client uploaded, waiting for the trigger
owned:        { accessories: [acc ids], images: [hashes] }   // Functions only
updatedBy, updatedAt
```
- Client writes `choice`, `pendingPhoto`, `updatedBy`, `updatedAt` only: family (admin/parent) for anyone, or `isOwnMember(memberId)` (kid devices included). Never `owned`.
- `choice.stage` is honoured only for members who are not kids; a kid's stage comes from their stars.

`members/{m}.look` — Functions only (mirrored by `onMemberAvatarWritten`, stage also by `stageLine`)
```
look: { v: 1, base: 'preset:pip' | 'image:<hash>' | null, stage: 0..3, wear: { top?, badge?, ring?, face? } }
```
- Absent `look` = the initial, exactly as today.

Stage for a kid (ADR-0004): `earned == 0` → 0; `earned >= 1` → 1; `bestStreak >= 3` → 2; `bestStreak >= 7` → 3. Never goes down.

`avatarPurchases/{id}`: client creates exactly `{memberId, accessoryId, requestedBy, requestedAt}`; trigger adds `status: owned | refused`, `reason?: notEnoughStars | alreadyOwned | unknownAccessory | shopOff | notAKid`, `settledAt`. Ledger line kind `accessory`, entry id `accessory_<purchaseId>`, counted as spent.

Shop switch: a household-level boolean `avatarShop` (default on), family-written, in whatever household settings document already exists (find the pattern; if none, a field on the household doc via the existing admin update path).

`avatarCreations/{id}`: client creates `{memberId, recipe, style?, buddy?: {creature, colour, loves, wears, power}, extra?: ≤60 chars, inboxId?, requestedBy, requestedAt}`; trigger writes `status: checking | drawing | ready | refused | failed`, `reason?`, `imageHash?`, `keepsakeId?`, `left?` (creations left this month, or for free: 0/1 ever).

`avatarKeepsakes/{id}`: Functions only. `{memberId, recipe, style, originalPath|null, buddy?, imageHash, createdAt, createdBy}`.

## Frame contract C-0023 rev 18 (additive)

`getFrameDay` → `household.members[]` gains optional
```
avatar: { base: { preset: 'nestling-pip-2' } | { image: '<hash>' }, layers: [ { slot: 'top'|'badge'|'ring'|'face', id: 'acc-crown' | 'moment-birthday-hat' } ] }
```
- The server resolves everything (stage into the preset asset id, worn accessories, today's moments in the household zone). The frame never computes.
- Absent or malformed `avatar` = the initial, as today. Unknown asset id = that layer not drawn (an unknown base = the initial).
- New HTTP endpoint `getFrameAvatar` on `frameJpegEndpoint`: POST `{secret, id}` → `200 image/jpeg`, only when `id` is a current member's image base; same status words as `getFramePhoto`; its own rate limit; `no-store`.

## Look and feel (the bar: it must be fun and make sense)

- On a phone: the avatar is drawn in a circle on the member's colour (the light fill), the base, then layers; a `top` layer sits over the rim (it may poke out of the circle), `badge` bottom-right overlapping the rim, `ring` round the edge, `face` inside on a Nestling. Initial fallback exactly as today.
- A kid's Nestling is an egg until their first star — the egg is a promise ("Earn your first star to hatch!"), and the hatch is a one-off celebration when it happens.
- Copy is warm and short, in the app's voice (see `app/lib/shared/copy/`), never cutesy jargon a parent wouldn't say. A pre-reader can use the kid surfaces by pictures alone.
- Twig appears only on AI surfaces (design-system ADR-0012).

## Guardrails for every agent

- Read the part's `CLAUDE.md` first (`app/`, `functions/`, `../NestPrep-Home/`) and follow it.
- **No comments** unless an edge case needs one (Daniel's rule).
- Never `git stash`, `git checkout -- .`, `git reset --hard`; never commit or push; never deploy. Other sessions are editing this tree: touch only what your task needs, and never revert a file you did not change.
- **Never start an emulator suite that includes Storage while another suite is running; Storage blobs live in one shared `$TMPDIR/firebase/storage/blobs`, and your suite deletes them on exit.** Check first: `curl -s http://127.0.0.1:4400/emulators`. Only the server agent runs emulator suites.
- `firestore.rules` and `storage.rules` are generated: edit partials under `rules/`, run `npm --prefix functions run rules:build`.
- The Flutter SDK is `~/development/flutter/bin` (not the one on PATH).
