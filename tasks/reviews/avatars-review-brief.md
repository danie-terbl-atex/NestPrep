# Avatars — review brief (one reviewer per portion)

You are a senior reviewer for NestPrep avatars. A build agent just finished the portion named in your launch message. Review its work for **correctness, robustness and completeness**, then **fix every valid finding** yourself. Daniel is asleep; nobody will answer questions. Use judgement, prefer the codebase's own conventions, and keep changes minimal and elegant.

## Read first
- `tasks/avatars-spec.md`: the contract every portion builds against.
- The plan: `~/.claude/plans/fizzy-snacking-pearl.md`.
- Godfather ADRs: avatars ADR-0001…0006, through `godfather context` or the `mcp__godfather__read_doc` tool if you have it (ids are in `tasks/avatars-spec.md`'s header or search "avatars").
- The `CLAUDE.md` of every part you touch (`app/`, `functions/`, `../NestPrep-Home/`, and the root one).
- The build agent's files: find them with `git status --short` and `git diff` (for NestPrep-Home, `git -C ../NestPrep-Home diff`). **Other sessions' unrelated in-flight changes are in the same tree**, so review only avatar work. For the paths in your portion, see your launch message.

## Look for
- **Spec and ADR conformance:** exact names, shapes, ids and regexes. Check that the Dart, TS, Kotlin and rules sides agree.
- **Security:**
  - every rule has a denied-case test;
  - a client can never write `owned`, `look`, ledger lines or another member's choice (unless the client is family);
  - kid devices are limited to themselves;
  - Storage size and type limits hold;
  - no member id leaks to the frame.
- **Robustness:**
  - trigger idempotency, retries and re-trigger loops;
  - transactions that read before they write;
  - missing or malformed data falls back to the initial exactly as before;
  - races between the choice and the mirror;
  - deleted members, and leaving or erasing an account;
  - offline behaviour, and cache invalidation through content-addressed ids.
- **Frame:** no allocation in `onDraw`; nothing decoded on the main thread; memory; old frames and old servers stay compatible (additive contract).
- **App:**
  - follows the kit (no private builders);
  - copy lives in one place;
  - light, dark, 200% text and 360 wide;
  - reduce motion;
  - fun, and it makes sense for kids and parents;
  - with the flag off it behaves exactly as today.
- **Completeness against the plan for this portion:** missing pieces, TODOs, stubs, untested paths.
- **Code quality:** no needless comments (Daniel's rule: comments only for edge cases), no dead code, no duplication of existing helpers.

## Then
1. Fix every valid finding. For each one you reject, say why.
2. Run the relevant checks:
   - `npm --prefix functions run build`, then the unit tests and `npm --prefix functions run test:rules` for server work;
   - `~/development/flutter/bin/flutter analyze --fatal-infos` plus the touched tests for app work;
   - `./gradlew test` plus a build for the frame.

   There are about 19 pre-existing Flutter failures from other sessions; report only new ones.
3. **Emulators:** never start an emulator suite that includes Storage while another suite is running; Storage blobs live in one shared `$TMPDIR/firebase/storage/blobs`, and your suite deletes them on exit. Check first with `curl -s http://127.0.0.1:4400/emulators`.
4. **Never** `git stash`, `git checkout -- .`, `git reset --hard`, commit, push or deploy. Touch only avatar work, and never revert files you did not change.
5. Write your report to `tasks/reviews/avatars-<portion>.md`, with these sections: findings (severity, file:line, fixed or rejected and why), checks run with their numbers, and anything left for Daniel. **Write the report file last**: its existence is the signal that you are done. Then exit.
