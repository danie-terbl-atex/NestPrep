# Avatars — deploy runbook

Written 2026-11-13 by the integration review. Project `nestprep-643b7`.

**Run 2026-11-13 ~07:00 SAST, from the uncommitted tree:** steps 1, 2, 3, 5 and 6 (both flags on) and 7. Step 4
needed no write. The quota is not raised yet: `image_pacing.ts` spaces pictures a minute apart until it is. The frame
build was sideloaded onto the attached RSFM156 only; step 8's release through the update agent is still to do.
`functions/.env.nestprep-643b7` gained empty `FRAME_SERVICE_WIFI_SSID`/`_PSK` (their defaults) so a
non-interactive deploy runs.
Every step is additive and both flags start off, so each can sit for a day before the next.

## Before you start

- **The tree holds other sessions' work** (recipes from a PDF, own recipes, frame pairing, the v5/v3
  legal text). Rules are one ruleset and are built from the whole tree, so the rules deploy ships
  those sessions' partials too: `household_recipes`, `lunch_box`, `meal_planning` and
  `rules/storage/paths/household_recipes.rules` are modified or new. Check with their owners first,
  or deploy after they have (lesson of 2026-11-05).
- Functions go out **by name only**, never `--only functions`.
- Commit first. `functions/test/unit/rules_are_generated.test.ts` and `site_is_generated.test.ts`
  pass on the tree as it is.

## 1. Rules and indexes

```sh
npm --prefix functions run rules:check
firebase deploy --only firestore:rules,storage --project nestprep-643b7
firebase deploy --only firestore:indexes --project nestprep-643b7
```

The index deploy adds the `avatarCreations` collection-group index (`status`, `requestedAt`). **Wait
until the console shows it as Enabled before step 2**: `sweepAvatarCreations` fails every hour with
`FAILED_PRECONDITION` without it.

## 2. Triggers, the sweep, and the functions that carry a look

```sh
npm --prefix functions run build
firebase deploy --project nestprep-643b7 --only \
functions:onMemberAvatarWritten,functions:onAvatarPurchase,functions:onAvatarCreation,\
functions:onAvatarKeepsakeDelete,functions:sweepAvatarCreations
```

Then the existing functions whose code changed for avatars. Without these a kid's stage never grows
and a removed member's pictures stay:

```sh
firebase deploy --project nestprep-643b7 --only \
functions:awardChorePoints,functions:reviewChore,functions:reserveRewardPoints,functions:settleReward,\
functions:removeMember,functions:deleteAccount,functions:closeHousehold,functions:exportAccountData,\
functions:setChildProfile
```

- `sweepAvatarCreations` is a schedule: it lands in `europe-west1` with a Cloud Scheduler job
  (`40 * * * *`, Africa/Johannesburg). Check the job exists after the deploy.
- `onAvatarCreation` runs at 512 MiB with a 300 s timeout. The runtime service account already holds
  `roles/aiplatform.user` (the lunch photo uses the same image model).
- Those nine existing functions also carry whatever else is uncommitted in their files. I saw nothing
  but avatar changes in `chore_points/`, `remove_member.ts`, `leave_erasing.ts`,
  `personal_data_export.ts` and `member_details.ts`; `git diff` them before you deploy.

## 3. The frame's functions

```sh
firebase deploy --project nestprep-643b7 --only functions:getFrameDay,functions:getFrameAvatar
```

`getFrameDay` starts sending `members[].avatar` (C-0023 rev 18 and 19) for any member with a look.
Old frames ignore it. No look exists yet, so nothing changes on a wall until step 5.
`frame_day.ts`, `frame_reads.ts` and `frame_policy.ts` also hold the other session's frame work;
check that session is ready for `getFrameDay` to go out.

## 4. AI settings — `appConfig/ai`

Absent keys read as on with the defaults, so **nothing has to be written**. To be explicit, or to
change the allowance, set by hand in the console:

```
features.avatarCheck     true
features.avatarPortrait  true
features.avatarCreate    { premiumMonthly: 12, freeLifetime: 1 }     (or just true for the same)
```

- Creations and portraits share that allowance. They are counted in `aiUsage/{month}.byFeature` and
  `aiUsage/lifetime`, never against `monthlyCalls`.
- Tries are capped at nine per creation the tier may make (9 a month free, 108 premium), in
  `aiUsage/{month}.allowanceAttempts.avatarCreate`.
- Kill switches: `features.avatarCreate: false` stops creations only; `enabled: false` stops all AI.

### Vertex image quota (do this before step 6)

Drawing uses `gemini-3.1-flash-image` on location `global` (`AI_IMAGE_MODEL`, `AI_IMAGE_LOCATION`).
The art run hit 429s at the default quota. In the Cloud console → IAM & Admin → Quotas, filter on
Vertex AI, *Generate content requests per minute per project per base model*, base model
`gemini-3.1-flash-image`, region `global`, and ask for an increase (60 a minute is plenty for the
beta). A 429 surfaces to the family as "couldn't make it, try again" and is refunded, so a low quota
costs goodwill, not money.

## 5. Flag `avatars` (phases 1–3), with the app build

1. Ship the app build that has the Studio (it reads the flag; with it off it behaves as today).
2. In `appConfig/flags`, set `avatars: true`.
3. Optional: `npm --prefix functions run seed:cloud-demo` gives the demo family looks. It touches only
   the demo household.

## 6. Flag `avatarCreations` (phases 4–5)

Only after step 4's quota is granted and step 5 has been quiet for a day:
`appConfig/flags.avatarCreations: true`. The trigger reads the flag per request, so no deploy.

## 7. Hosting — privacy v6 and terms v4

The legal review listed four promises the text makes that the code had to keep first. Checked on
2026-11-13, in the tree:

| # | Promise | Holds? | Where |
|---|---|---|---|
| 1 | A plain leave keeps the profile's avatar; removal or account deletion deletes it | **Yes** — the text now says what the code does | `leave_household.ts` touches no avatar; `remove_member.ts:81`, `leave_erasing.ts:84` delete |
| 2 | A refused or failed request's drawing or photo is deleted | **Yes** | `avatar_creation.ts` deletes the inbox in a `finally`; a run that dies is swept within two hours by `sweepAvatarCreations`. Emulator tests assert the empty prefix in both cases |
| 3 | A photo avatar is deleted when changed or removed | **Yes** | `member_avatar.ts` `photosToDrop`, then `deleteObjects`; emulator test "deletes a photo once it is not worn" |
| 4 | Keepsake and creation documents go with the member | **Yes** | `forgetAvatarRecords` in `removeMember` and `leaveErasing`; emulator test "go with a member who is removed, and with one who deletes their account" |

All four hold **once steps 1 and 2 are live**. So Hosting goes after them, and before step 5 (the
policy should be up before the feature is):

```sh
firebase deploy --only hosting --project nestprep-643b7
```

`hosting/public/` in the tree is already built from v6/v4 (`site_is_generated` passes). It also
carries the other session's v5/v3 text, which goes live in the same deploy. Raising the versions
makes the app ask everybody to accept again.

One gap the text does not cover either way: a reference uploaded to the inbox whose request document
was never written (the app died between the two) is not swept. It is 2 MB at most and goes with the
member.

## 8. The frame release

1. `../NestPrep-Home`: `versionCode` is 13 (`0.13.0`), bumped by the other session; it carries their
   pairing and chores work too. Bump again if 13 was already published.
2. `node tools/release/publish.mjs home --notes "Avatars on the wall"` — builds, checks the signer,
   uploads, creates a draft.
3. Internal Tools → Frames: promote the draft to our own frames first (WF-1009 / RSFM101 "Frame",
   RSFM156 "Frame Pro"). The agent installs overnight (01:00–05:00), or at once with *Install now*.
4. Look at both: every initial of 26 dp and up shows the Nestling; Mia in a crown; a member whose
   look is the initial plus a hat; the celebration's payoff. Then promote to the fleet.

Order does not matter against the server: an old frame ignores `avatar`, and a new frame with an old
server draws initials.

## Watch after

- **Logs, `onAvatarCreation`**: `avatar creation settled` with `status` and `reason`. A run of
  `failed`/`unavailable` is the quota or the model; a run of `refused`/`declined` is the filter.
  `avatar creation broke` is a bug.
- **Logs, `sweepAvatarCreations`**: `stuck avatar creations swept {failed, ready, refunded}`. It
  should be all zeros. Anything else means runs are dying: look for timeouts on `onAvatarCreation`.
- **Logs, `ai call failed`** with `feature: avatarCreate | avatarCheck`, and Vertex 429s.
- **`aiUsage/{month}`** on a test household: `byFeature.avatarCreate` goes up by one per picture kept,
  and back down on a refund; `calls` and `attempts` must not move for a creation.
- **`getFrameAvatar`**: 404s are expected for a hash nobody wears now; 429 is its rate limit (60 an
  hour per frame).
- **Storage** under `households/*/avatars/*/inbox/`: should stay empty within two hours of any request.
- **Cost**: one creation is up to three text checks and one image. Twelve a month per premium
  household is the ceiling; the kill line is `features.avatarCreate: false`.

## Rolling back

Set the flag off (`avatarCreations`, then `avatars`). Looks stay on member documents but the app stops
drawing them. To take avatars off the walls too, redeploy the previous `getFrameDay`. Rules and
triggers can stay; with the flags off nothing writes to them.
