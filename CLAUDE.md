# NestPrep — NullState app `nestprep`

This repo is code for the NullState app **nestprep**. Its memory — what it is for, what v1 is, every
decision and why, what is in flight and what it breaks — lives in the NullState vault, not here:

    ../nullstate-vault/   (also $NULLSTATE_VAULT)

## Before any task

1. Run the **nullstate-memory** skill. It reads `nullstate-global.md`, then
   `nestprep-project/work-index.md`, then only the feature notes the task needs.
2. State back the constraints, whether the work is in v1, and the blast radius before writing code.
3. If the task contradicts an ADR or the verdict, say so; do not silently comply or refuse.

## After any change

A change is not done until the vault reflects it, in the same change: feature overview, ADR
ledger, phase note's Next action, integration-map rows. Then run
`python3 ../nullstate-vault/tools/vault-lint.py` and clear every error. Delivery procedure: the
**nullstate-deliver** skill.

Never put secrets or customer data in the vault.

## Running this app

This folder is the NestPrep monorepo: one Firebase project, three parts. Each part has its own
`CLAUDE.md` with build, run and test instructions and the gotchas for that codebase:

- `app/` — the Flutter client, Android and iOS from one codebase
- `functions/` — Cloud Functions (TypeScript, 2nd gen); only what Security Rules cannot express
- `firebase.json`, `firestore.rules`, `storage.rules`, `firestore.indexes.json` — the Firebase config
  at the root; the two rules files are the authorisation layer and every rule has a denied-case test.
  **Both rules files are generated** from `rules/` — see below.

`DesignsInsp/` is design inspiration, not source; it is gitignored on purpose.

**A build with no define talks to the real project** (foundation ADR-0011, which reversed
ADR-0003's provisional default on 2026-09-18). That means a plain `flutter run` reads and writes the
one real household's data, and there is no second project behind it. Opt into the Local Emulator
Suite for anything destructive, and for the seeded sign-in shortcut, which exists on that target
only:

```sh
flutter run --dart-define=NESTPREP_BACKEND=emulator
```

The suite needs no cloud *access* — the client configuration is committed — but it does run under
the real project id (foundation ADR-0008):

```sh
firebase emulators:start --project nestprep-643b7     # Auth 9099, Firestore 8080, Functions 5001, Storage 9199, UI 4000
npm --prefix functions run seed                       # three signed-in users for the emulator
```

The project id is `nestprep-643b7`. It lives here and in the generated config files, never in the
vault. A `demo-` project id no longer works: the Android Cloud Functions SDK validates the client
configuration before every callable, and only a real project has any — foundation ADR-0008 and the
vault lesson on what Auth and Functions need that Firestore does not.

What keeps an emulator build off the cloud is `bootstrapFirebase`, which points Firestore, Auth,
Functions and Storage at the emulator in one place before anything uses them. **A Firebase service added
later is redirected there or not at all.**

The suite is still the environment for the rules suite, the Functions tests and
`app/integration_test/`; those name their target explicitly and are unaffected by the default. Start
it before an emulator run, because a Firestore **write** against a backend that is not listening
never completes and never throws — the app sits on "Getting things ready" for ever with no error.
That is a vault lesson, not a bug to rediscover.

## Firestore rules are partials, built into one file

`firestore.rules` is generated and committed; never edit it (foundation ADR-0012, `ENG-05`). Each
feature owns one partial, and adding one is a new file nobody else touches:

    rules/firestore/shared/*.rules      functions every match may call (who the caller is, grants, shapes)
    rules/firestore/root/*.rules        top-level  match /<collection>/{id} { … }
    rules/firestore/household/*.rules   blocks inside  match /households/{householdId} { … }

A partial is written **without** its scope's indentation — the builder adds it — and files are read
in name order, which does not change what the rules mean. To add a feature's rules:

1. Create `rules/firestore/household/<feature>.rules` (or `root/`) holding that feature's `match`
   blocks and its own helper functions. Gate every household read and write on the area grant —
   `canView(householdId, '<area>')`, `canEdit(…)`, `hasOwnOnly(…)` with `ownMemberId(…)` — never on
   a bare `isMember` or a role name; that makes it right for helpers, carers, kids and kid devices
   at once (household ADR-0003, accounts ADR-0004). Stamp authorship with `isOwnMember`.
2. A helper several features need goes in a new `rules/firestore/shared/<name>.rules`; do not grow
   `access.rules` or `shapes.rules` for one feature. **Every partial in a scope shares one
   namespace**: a function a feature keeps to itself is prefixed with the feature
   (`isFamilyProfile`, `isDocumentName`), because two partials declaring the same name fail to
   compile — and the emulator says so only when the suite starts.
3. `npm --prefix functions run rules:build`, and commit the partial and `firestore.rules` together.
   `npm run test:rules` builds first; `functions/test/unit/rules_are_generated.test.ts` fails when
   the committed file is not what the partials build to, and when a partial passes 300 lines.
4. **A merge conflict in `firestore.rules` is never resolved by hand**: take either side, run
   `rules:build`, `git add firestore.rules`. Conflicts belong in the partials, and two features that
   each add their own file have none.

## Storage rules are partials too

`storage.rules` is generated the same way, by the same command, from `rules/storage/`
(foundation ADR-0013, `ENG-05`); never edit it:

    rules/storage/shared/*.rules   functions every Storage match may call (caller, grants, document file limits)
    rules/storage/paths/*.rules    one feature's  match /households/{householdId}/<its path>/…  blocks, full path

Storage has no parent document to nest under, so a `paths/` partial spells out the whole object
path. Gate on the token-claim `canView`/`canEdit` in `shared/caller.rules`, or — when a grant must
bite on the next request rather than within the hour — read Firestore live the way
`document_vaults.rules` and `home_care.rules` do, prefixing the helpers with the feature. Then
`npm --prefix functions run rules:build` and commit the partial with `storage.rules`; the same
check test and the same never-by-hand rule for conflicts apply.

## Hosting

The public site — a landing page, the privacy policy, the terms, and the account-deletion page the
Play Store links to — is Firebase Hosting, served from `hosting/public/`. That folder is
**generated and committed**, like the rules files; never edit it:

    app/assets/legal/*.md         the privacy policy and terms — one source, bundled by the app too
    hosting/src/                  the layout, the other pages, site.css (the only place a colour is), delete-account.js
    hosting/tools/build-site.mjs  renders the documents, fills the layout, copies the logo and fonts from app/assets

Edit a source, then `npm --prefix functions run site:build` and commit it with `hosting/public/`.
`functions/test/unit/site_is_generated.test.ts` fails when the two differ, when a page loads
anything from another origin or carries inline script, and when `site.css` drifts from
`nest_colors.dart`. `/api/account-deletion-request` is rewritten to the `requestAccountDeletion`
Function. Changing a legal document's text means raising its `version`, which makes the app ask
everybody to accept it again. Deploying is `firebase deploy --only hosting --project nestprep-643b7`
(it runs `site:check` first), done by Daniel or the orchestrator — never from a feature branch.

Never `git stash`, `git checkout -- .` or `git reset --hard` here.
