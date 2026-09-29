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
  at the root; the two rules files are the authorisation layer and every rule has a denied-case test

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

Never `git stash`, `git checkout -- .` or `git reset --hard` here.
