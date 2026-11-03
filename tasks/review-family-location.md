# Review — family location (Life360-style), uncommitted work of 2026-11-02

Independent, adversarial review. Read only: nothing in code, rules, config or Godfather was changed.
Method: Godfather route + live-location overview, ADR-0004..0008, household ADR-0008, accounts ADR-0010,
notifications ADR-0004, Phase 2; then the code. Rules, Functions, privacy text, TTLs, seed and memory
were reviewed directly; the Android engine, iOS engine and Dart side were each read in full by a
separate reviewer and their top findings re-checked against the code here (marked **verified**).
Rules mutations were run on a scratch copy of `firestore.rules` on isolated ports (8480/9580) — the
shared tree and Daniel's dev suite were not touched.

Legend: **verified** = re-read in code by me; *reasoned* = follows from code + documented platform
behaviour, not run on a device. Nothing here has been run on a phone (neither has the feature).

---

## Critical

### C1. Signing out never stops location sharing; on Android the engine keeps sharing as the signed-out person — **verified**
- `app/lib/features/accounts/state/session_controller.dart:123` and `firebase_auth_gateway.dart:147`
  call `_auth.signOut()` and nothing else. No sign-out path (account menu, kid home `_signOut`,
  consent screen, `foreign_session_guard.dart:35,43`, account deletion) calls `AlwaysSharing.stop`,
  `LocationEngine.stop` or `LocationReporter.stop`.
- Android: `LocationService.kt:97` checks `auth.currentUser` only when the engine starts; the `:location`
  process holds its own in-memory `FirebaseAuth` with a still-valid refresh token and has no auth-state
  listener. The rules still pass (`hasClaimed` = `claimedBy == uid`, unaffected by sign-out).
- **Scenario:** a parent signs out of a shared/family tablet, or a kid device is signed out and handed
  to a sibling. The FGS keeps writing that person's live position (24 h lease renewed), trail and place
  events until the process dies; the notification still says "Sharing your location". The privacy
  policy (`privacy-policy.md:97`) promises "It also stops by itself if … you sign out" — untrue.
- iOS stops itself on a nil user (`FirebaseLink.swift:29`) but leaves `memberLocations/{m}` up, so the
  family sees "sharing" at the last spot for up to 24 h.
- *Reasoned:* Firebase Auth on Android is not multi-process safe; a token refresh in `:location` can
  write the old user back into the shared prefs file and resurrect the session on next main-process launch.
- **Fix:** one sign-out hook used by every sign-out path and erasure: `AlwaysSharing.stop` +
  `LocationReporter.stop` (best effort, not awaited on the network) *before* `_auth.signOut()`. In
  `:location`, add `addAuthStateListener` → `halt(SignedOut)` and compare `currentUser?.uid` to the
  config's uid before each write. On iOS, delete the live doc through the secondary app before
  `link.signOut()`. Add a Dart test: sign out while always-sharing → engine.stop called.

### C2. iOS writes nothing while the phone is locked — **verified**
- `app/ios/Runner/Location/FirebaseLink.swift:27`: `guard UIApplication.shared.isProtectedDataAvailable
  else { return .waiting }` (and `:21` in `signedInUid()`). `isProtectedDataAvailable` is false ~10 s
  after every lock on a passcode device, not only before first unlock.
- **Scenario:** phone in a pocket/bag → no live, trail or event write until the person unlocks it.
  The "where is everybody" map is empty of exactly the people who are out. Each wake also keeps
  `liveWanted` set, so `isBusy` stays true and a background task runs to expiry → battery.
- FirebaseAuth stores its user `AfterFirstUnlockThisDeviceOnly`, so the keychain is readable while
  locked; before first unlock `UserDefaults` (the config) is unreadable anyway.
- **Fix:** drop the guard; treat "default user nil *and* protected data unavailable" as waiting. Make
  the `protectedDataDidBecomeAvailable` pump async so Auth reloads first.

---

## High

### H1. One denial in *any* lane counts toward "refused" and stops sharing — **verified (Android), reviewer-verified (iOS)**
- Android: one `Denials` shared by live, day and event lanes (`WriteLane.kt:5-17`, `Engine.kt:16`,
  `WriteLane.kt:46`). Two denials in a row → `refused()` → `halt(Refused)` → `clearConfig()` +
  `clearTrail()`. iOS: `FirestoreWriter.swift:206-228`, same effect.
- Ordinary triggers that always deny twice:
  1. **A place is deleted** while another phone (app closed) still fences it: the event create fails
     `exists(places/…)` (`location_trails.rules:37`). Places reach the engine only via
     `AlwaysSharingGuard`, which runs only with the app open.
  2. **iOS lost ack:** an event committed but not acked is resent as `set` on an existing doc → an
     update → `allow update: if false`.
  3. **Day cap after ledger reset:** stop/start or a new sharer clears `DayLedger`; a server day doc
     near 3,000 points denies every flush.
  4. **Restart within 10 s:** a fresh engine has `ackedAt == null` and trips the live pace rule.
- **Scenario:** a parent deletes "Gran's"; the child's phone arrives there, the engine stops, the
  config and buffered trail are wiped, and the app later says "Premium may have ended". On Android, if a
  live ack lands between the two event denials the lane instead retries every 30 s forever.
- **Fix:** only live-lane denials count toward stopping. A denied event or day write is dropped (and
  logged). Prune queued events on `setPlaces`. Refresh places natively with one read on begin and heartbeat.

### H2. After ~24 h offline the engine stops itself and deletes the buffered trail — *reasoned*
- `Payloads.kt:24,34,41` (and the Swift twin) fix `sharingUntil` and `expiresAt` from the device clock
  when the payload is built; the SDK replays that same payload on reconnect.
- **Scenario:** camping or abroad without roaming for a day. On reconnect the live write fails
  `until > request.time` and the day write fails `expiresAt > request.time + 29d` → two denials →
  refused → sharing off and up to 3,000 offline points deleted.
- **Fix:** never count a denial of a write queued more than a few minutes; rebuild the payload with a
  fresh lease or expiry and retry. Only refuse on two denials of fresh payloads.

### H3. Leaving a household leaves your position and 30-day history visible to it — **verified**
- `functions/src/household/leave_household.ts:31-32` calls only `detachMember`
  (`membership.ts:50-72`), which unclaims the profile and drops the membership. It deletes neither
  `memberLocations/{m}` nor `locationTrails/{m}`. The app's *Leave* button calls this callable
  (`callable_household_directory.dart:66`), not `leaveErasing`.
- The ADR-0004 constraint lists `removeMember`, `leaveErasing` and the export, and misses this path.
- **Scenario:** a separated co-parent leaves the household. The household keeps seeing their last pin
  for up to 24 h and their full 30-day trail (where they slept, where they work) until the TTL.
- **Fix:** in the same `leaveHousehold` transaction, delete `memberLocations/{memberId}`, then
  `recursiveDelete(trailRef)`. Add an emulator test, and add `leaveHousehold` to the overview constraint.

### H4. Place-event dedupe has no time bound: one missed exit silences every later arrival — **verified**
- `functions/src/live_location/place_event_delivery.ts:104-107`: `if (previous === kind) return null`,
  where `lastPlaceEvents[placeId]` is kept for ever. Nothing else resets it (grep: only this file).
- Missed exits are routine. iOS drops region exits. The engines ignore an exit within 3 min of an
  arrival. The engine is stopped and restarted. A lane drops a write (H1).
- **Scenario:** Mia's exit from school is missed on Monday. On Tuesday her arrival is deduped as
  "repeat" and on every school day after, until a leave lands. "Tell me when they get to school", the
  headline feature, fails silently.
- **Fix:** store `{kind, at}` and treat a repeat as a duplicate only within a short window (minutes),
  or clear the per-place state when the engine starts. Add an emulator test: arrive, (missed leave),
  arrive 6 h later → sent.

### H5. The first "Always share" tap on Android 11+ always fails — **verified**
- `always_sharing.dart:89` calls `requestAlways()` once. With nothing yet granted,
  `LocationChannel.kt:174-184` asks only for fine and coarse location (Android 11+ refuses background
  in the same prompt). The result is `whileInUse`, so `start` throws `alwaysRefused` at `:91-92`.
- **Scenario:** every new Android user taps Always, chooses "While using" as offered, and is told
  always-sharing was refused.
- **Fix:** when the first request returns `whileInUse`, explain and request background straight away in
  the same flow. Add a fake-engine test: denied → whileInUse → always.

### H6. Store-policy risk: the disclosure and policy promise a pause control that does not exist; the iOS indicator is off — **verified**
- `location_copy.dart:42`: "You can pause it any time, here or from the notification."
  `privacy-policy.md:97`: "you can pause it in one tap". `SharingNotification.kt` has no action, only a
  tap that opens the app.
- The disclosure lacks Play's required "even when the app is closed or not in use" wording, and it
  never mentions the motion (activity-recognition) prompt that follows it.
- iOS: `LocationSensor.swift:28` sets `showsBackgroundLocationIndicator = false`, so a child's phone
  shows nothing while it reports in the background.
- **Scenario:** the Play prominent-disclosure review rejects it, or a parent or child is told something
  false about how to stop.
- **Fix:** add a Pause action (a broadcast receiver in `:location` that stops, deletes the live doc and
  clears the config), or drop the claim everywhere. Add "even when the app is closed or not in use" and
  the motion use. Consider turning the iOS indicator on (at least on kid devices).

### H7. Kid phones: foreground cadence forever, no geofences, no lapse guard, and a window can't be stopped — reported independently by two reviewers
- `AlwaysSharingGuard` is mounted only in `household_shell.dart:150`, and kid routes bypass the
  household shell. `AlwaysSharing._foreground` starts `true` (`always_sharing.dart:59`) and only the
  guard's lifecycle observer changes it.
- `kid_location_sheet.dart:164` starts sharing with no `places`, and nothing on a kid device ever
  sends `setPlaces`.
- **Scenario:**
  - A kid phone always-shares at the open-app cadence (Android: fixes every 10 s, live writes every
    20 s / 25 m): about 6× ADR-0004's writes and a flat battery.
  - It produces no arrive or leave events, so the alerts parents care about most never fire.
  - The lapse guard never runs on it.
  - The window branch of the kid sheet (`:128-150`) has no Stop and never reads the kid's own doc,
    which contradicts its own "Only you can start or stop this". It has no loading or error state either.
- **Fix:** move the lifecycle observer into `AlwaysSharing` (app-wide), and send `foreground: false`
  when not resumed at start. Read the household's places in the kid flow and pass them on start and on
  change. Give the kid sheet the same until/Stop control and its loading and error states. Test the kid sheet.

### H8. The 30 s ticker turns an error or loading state into "everybody is not sharing" — **verified**
- `live_location_controller.dart:121`: `Timer.periodic(recount, (_) => _publish())`, and `_publish`
  (`:150-161`) always sets `AsyncData`. The places listener at `:116` guards on `_view is AsyncData`;
  the ticker does not.
- **Scenario:** a parent revokes a helper's location grant mid-listen, or a read is slow or offline.
  Within 30 s the error/retry (or the spinner) becomes a list saying every child is "Not sharing".
  A parent is told something false and calming.
- **Fix:** have the ticker republish only while `_view is AsyncData`. Add a fake-clock test past 30 s after an error.

### H9. Android still detection and flushes run on a timer that stops in deep sleep — **verified (`LocationService.kt:107` uses `handler.postDelayed`)**
- All engine timers ride `postDelayed`, which runs on `uptimeMillis`: the 5-minute still check, the
  15-minute flush, retries, backoff and pace waits. Activity-recognition STILL ENTER only records
  motion (`Engine.kt:84-89`) and never calls `goStill`.
- **Scenario:** after arriving, with no fix passing the 25 m filter, the CPU sleeps, so the still check
  slips by hours. The BALANCED 30 s request keeps running and no heartbeat is armed. Battery drains
  while the phone stays in "moving".
- **Fix:** use `AlarmManager.ELAPSED_REALTIME_WAKEUP` for the still check and the flush, make STILL ENTER
  trigger `goStill`, and hold a time-limited partial wakelock from `onReceive` (`goAsync`) until the write is acked.

### H10. The Android heartbeat republishes a stale position as fresh — **verified (`Engine.kt:91-96`)**
- `onHeartbeat` writes `lastFix` with a server `reportedAt` and takes no new fix. It never re-adds the
  still fence. `GeofenceReceiver.kt:12` drops `GEOFENCE_NOT_AVAILABLE`.
- Android removes every geofence when location is switched off or Play services data is cleared. With
  motion permission denied (it is optional), nothing ever wakes the engine again.
- **Scenario:** every hour the family is told "at home, just now" while the person is across town.
  (iOS has the same contract limit: the payload carries no fix time, so a stale fix always looks fresh.)
- **Fix:** on heartbeat, call `getCurrentLocation(BALANCED)`, re-add the still fence, and listen for
  `PROVIDERS_CHANGED`. Consider allowing a `fixedAt` field in the rules so a stale fix reads as stale.

### H11. Android: a config that outlives a failed or killed engine silently resumes sharing later — *reasoned from code*
- `LocationChannel.start` persists the config before `launch()` and leaves it on `notStarted`
  (`LocationChannel.kt:101-107`).
- `promote`'s `IllegalStateException` path calls `halt(null)`, which keeps the config.
- Revoking the permission kills the process, so `PermissionRevoked` is never written.
- `AlwaysSharing.stop` skips `_engine.stop()` when its cached `_status` says not running (`always_sharing.dart:126`).
- **Scenario:** the UI says "not sharing". Then a reboot, a geofence or an activity event starts the FGS
  and sharing starts again without the person acting. That is a consent breach (ADR-0008: sharing is
  the member's own act).
- **Fix:** clear the config on every failed launch or halt. `stop()` always calls native `stop`, which
  clears the config whatever state the service is in.

### H12. Starting Always while a window share is open leaves two writers on one document — two reviewers
- `share_location_card.dart:83-104` offers Always while a window is open, and `startAlwaysSharing`
  never stops `ForegroundLocationReporter`. Each mode flip is exempt from the pace rule
  (`live_location.rules:55`), so the two writers alternate freely.
- When the window ends, `_closeWindow` deletes the doc under the running engine.
- **Scenario:** an always-on member vanishes from the map for up to an hour (still phone). It breaks
  "one reporter writes per mode".
- **Fix:** stop the reporter (no delete) before `AlwaysSharing.start`, or hide Always while a window is open.

---

## Medium

1. **iOS: App Check is skipped for any background-launched process** (`LocationEngine.swift:57-60`,
   `FirebaseLink.swift:70`). After 5 s the default app is configured natively with no provider, and
   FlutterFire only installs its provider when the plugin registers. A location relaunch can keep that
   process alive for days, and if the user then opens the app, every Flutter call runs without App
   Check. **Fix:** never configure the default app natively; configure `nestprep-location` from
   `FirebaseOptions.defaultOptions()` behind a native App Check provider. (Not verified whether enforcement is on.)
2. **iOS: a relaunch before first unlock can leave the engine dead for the whole process**
   (`LocationEngine.swift:65-68, 301-308`). `resume()` runs only at launch and on
   `protectedDataDidBecomeAvailable`, which a suspended process can miss. **Fix:** call `resume()` at
   the top of every delegate callback when `config == nil`.
3. **iOS: significant-change and cached fixes drive the state machine unfiltered**
   (`LocationEngine.swift:313-338`). A 1–3 km significant-change fix "leaves still" and restarts full
   updates (battery), and old cached fixes go out as live positions. Also, with no fix within 5 min the
   still alarm re-arms at a past deadline → `asyncAfter(0)` loop → **main queue at 100% CPU**
   (`:218-224`). **Fix:** gate on accuracy (≤100 m) and age (≤60 s); don't arm the alarm without an anchor.
4. **iOS Always upgrade is spent too early** (`PermissionDesk.swift:40-42`). `askedAlways = true` is set
   on the `.notDetermined` path as well, so a user who picks "While Using" never gets the upgrade
   prompt, and `openBatterySettings` does nothing on iOS (`LocationChannel.swift:51`): no way to
   Settings. Precise Location off (`accuracyAuthorization`) is never read either, so with it off every
   fix is >100 m → no trail, no regions.
5. **iOS arrivals wait for the next wake** (`LocationEngine.swift:266-271`). The 60 s dwell is a
   main-queue timer, and nothing keeps a suspended app awake for it, so the arrival can be hours late.
   **Fix:** confirm with `requestLocation` or the visit, inside a background task.
6. **iOS lease renewal while still depends on `BGAppRefreshTask` only** (`LeaseRefresh.swift`). It
   does not run in Low Power Mode or with Background App Refresh off. A still phone lapses at 24 h
   while the app still says "sharing". Consider a silent push (`remote-notification` is already declared).
7. **Late arrivals are told as fresh.** An event's `at` is the server's write time, and a crossing
   queued offline or behind the dwell is pushed hours later as "Mia arrived at school"
   (`place_event_delivery.ts`). **Fix:** let the device send its crossing time within a bounded skew,
   or have the engine drop crossings older than N minutes.
8. **No pace or volume limit on place events** (`location_trails.rules:32-39`). Each create is a
   Function invocation, a transaction and N pushes. A flapping fence (each cycle >3 min) or a runaway
   client alternating arrive/leave is unlimited. **Fix:** a per-place minimum interval in
   `deliverPlaceEvent` (with H4's `{kind, at}`), plus a daily cap per member.
9. **The privacy policy is untrue in three places** (`privacy-policy.md:97,104,108`).
   - "Helpers, carers and kids see it only if a parent grants them": kids default to `view` (`access.ts`
     ROLE_DEFAULTS), and a helper claimed before ADR-0003 with no grant sees it (edit everywhere).
   - "Anybody else is told only that somebody arrived": they see the name and place in the inbox detail.
   - "Stops by itself … if you sign out": see C1.
   - Leaving a household is not mentioned (see H3).
10. **TTL policies on collection groups `days` and `events`** (`firestore.indexes.json:277-288`).
    `events` is also the calendar's `households/{h}/events`. Nothing there has `expiresAt` today, but a
    future field of that name on calendar events would be deleted silently, and the override also drops
    their `expiresAt` index. Renaming is cheap now and impossible later. **Fix:** rename the
    subcollections to `trailDays` and `placeEvents` before the first deploy.
11. **ADR-0004's cost model leaves out the reads the rules make.** Each live write evaluates
    `isOwnMember` (member doc get), `hasPremium` (exists + get on the entitlement), and through the
    shift/area helpers the household doc. A day write and an event (`exists(place)`) are the same. That
    is ~2–3 billed reads per write, ~200–270 reads per member-day on top of the ~60 claimed. Still cheap
    at today's scale, but the ADR's "~60 reads" is wrong. Re-state it.
12. **Switching households leaves a stale pin.** `begin()` for household B never deletes A's live doc,
    so A shows "last seen" for up to 25 h (a window: up to 4 h). B's screen never says the phone is
    already sharing with A. The unflushed trail for A is also cleared.
13. **Pause or Stop while offline spins forever** (`always_sharing.dart:124-131`,
    `foreground_location_reporter.dart:84-89`). They await the delete's acknowledgement (the repo's own
    lesson: an offline write never completes). `_busy` stays true. **Fix:** fire the delete, update
    local state at once, and log failures.
14. **`AlwaysSharingGuard` calls `notifyListeners` during build and stops more than once**
    (`always_sharing_guard.dart:56-61`). `stopForLapse` runs synchronously from `didChangeDependencies`,
    re-enters, and sends several stop calls and deletes. It also sets `_stoppedBecause = refused` even
    when the stop failed (`:136`). **Fix:** a post-frame callback with an in-flight flag. The guard has no test.
15. **`/where` is not gated** (`household_place_redirect.dart`). A deep link or push tap
    (`notifications_route.dart:65`) opens it for a member with `location: none`, the listeners fail,
    and combined with H8 they see "nobody is sharing". **Fix:** add the `wherePathFor` prefix → `HouseholdArea.location`.
16. **Two devices for one member compete.** Writes inside 10 s (live) or 30 s (day) are denied, two
    denials stop whichever engine loses, and the 3,000 count is kept per device. Pausing on one phone
    deletes the doc while the other rewrites it.
17. **Android stop flushes one batch and deletes the rest** (`Engine.kt:204-213` →
    `LocationService.finish` → `clearTrail()`). Pausing within 30 s of the last flush, or with >120
    points buffered, loses points. iOS: same (`FirestoreWriter.swift:81`).
18. **Android heartbeat can't restart a dead FGS on 12+** (`AndroidSensors.kt:69`):
    `setAndAllowWhileIdle` is inexact and is not an FGS-start exemption, and `launch` swallows
    `ForegroundServiceStartNotAllowedException`. Recovery then depends only on geofence, AR and boot
    events. Use exact alarms when allowed, or WorkManager.
19. **`POST_NOTIFICATIONS` is never requested by the sharing flow.** On Android 13+ with it denied, the
    FGS notification is hidden from the shade, and the only visible sign of sharing is gone. Ask for it
    in the disclosure flow.
20. **Erasure leaves the erased person's name in other people's inboxes.** "Mia arrived at Parkhurst
    Primary" stays in every family member's `notificationInbox` for 30 days after Mia's account is
    erased or she is removed. Decide whether POPIA erasure should sweep `source.kind == placeEvent`
    items for that member.
21. **The cloud-demo seed fires real pushes.** `tools/cloud-demo/location.mjs` creates two `events`
    docs with alerts on. On the first seed (or after teardown) `notifyPlaceEvent` fires and pushes
    "Pieter arrived at Parkhurst Primary" / "left Home" to the demo family's real phones, and writes
    `lastPlaceEvents`. Fine if intended, but say so, or seed the inbox items directly.
22. **The place editor.**
    - `_PlaceEditorRoute` (`live_location_routes.dart:106`) spins forever on a refused read, and a
      missing id opens a blank editor whose Save creates a new place.
    - With the map on, "Use where I am" doesn't move the camera, so the first pan overwrites the centre.
    - The slider has no `semanticFormatterCallback`, so a screen reader announces a percentage, not metres.
    - The name field has no `maxLength`; Save just greys out past 40 characters.
23. **The history screen shows raw coordinates** for stops that aren't a place
    (`member_history_screen.dart:233`). `StreetNames` is used only in the live row.

## Low

- **The Android unknown-zone fallback** quietly becomes GMT (`TrailDays`), so day docs split at the
  wrong midnight. With approximate location only, place fences never register, and nothing says so.
- **The Android `startForeground` order:** `onStartCommand` halts before `startForeground` when there
  is no config (*speculative* crash on some versions).
- **iOS:**
  - `Dictionary(uniqueKeysWithValues:)` crashes on duplicate place ids (`LocationSensor.swift:78`).
  - Dart never calls `ready()` (`method_channel_location_engine.dart:105` has no callers).
  - `configureFirebaseIfAlone` doesn't re-check whether Flutter started during the 5 s.
- **The export**
  (`personal_data_export.ts`): `days.limit(40)` and `events.limit(500)` are unordered and carry no
  `cutShort`, which BE-08 requires. The trail's parent doc (`lastPlaceEvents`) is neither exported nor
  removed by "clear my history", and it has no TTL.
- **The day rules don't validate the point shape** (`location_trails.rules:46-47`). An own member can
  replace points (only the count is checked) or stuff any value up to 1 MiB. It's their own data, so low.
- **Live pace bypass:** `delete` + `create`, or flipping `mode` on every write, bypasses the 10 s rule
  (`live_location.rules:53-56`). A runaway client is the only one hurt.
- **No tolerance for a fast clock:** the 4 h window has none (`live_location.rules:45`). A phone clock a
  few seconds fast has its "4 hours" share refused.
- **Small Dart gaps:**
  - `StreetNames` caches a failed lookup for the session.
  - `FamilyMap.didUpdateWidget` compares `path` by identity, so the camera re-frames on every places update.
  - `notStarted` is shown as `permissionRefused`.
  - The map's semantics label is only "Where we are".
- **A stale comment:** `access.rules:92-93` (`hasClaimed`) still says sharing a location needs your own
  login (superseded by accounts ADR-0010).
- **An iOS test hazard:** the XCTest host runs the real `AppDelegate`, so a saved config on the
  simulator with no emulator define resumes and writes to the real project.

---

## Tests — claims vs reality

- **The counts.**
  - Dart: 101 tests, all pass, `flutter analyze` clean. The claim is true.
  - Android: 28 JVM tests, real, with fake time.
  - iOS: 48 location XCTests + 1 template = 49. The phase doc's "46" is wrong; the overview's "49" counts the template.
- **"Four states and dark at 200% for each new screen" is partly false:**
  - History: no loading test.
  - Place editor: only the 200% test.
  - Kid sheet: no tests at all.
  - Everything runs list-only (`showMap` false).
- **Not covered at all:**
  - `AlwaysSharingGuard`, `KidLocationSheet`, `StreetNames`, and `MethodChannelLocationEngine` beyond `startArguments`.
  - Sign-out, the ticker over an error, and the two-step Android permission.
  - Android `LocationService` and `FirestoreStore.toFirestore` (GeoPoint, Timestamp, FieldValue, merge).
  - iOS `LocationEngine`, `FirestoreWriter`, `FirebaseLink`, `LocationSensor`, `PermissionDesk`.
- **The "three-language contract" fixture is never checked against the rules.** The JVM and XCTest
  fixture tests compare logical maps or key sets with the JSON; no rules test reads
  `location_payloads.json`. The iOS fixture path (`#filePath`-relative) works only on the simulator.
- **Rules mutations** (isolated scratch copy, 45 baseline green):

| Mutation | Result |
|---|---|
| drop `hasPremium` from the continuous lease | killed (1 test) |
| drop the 30 s day pace | killed (1) |
| drop `exists(place)` on event create | killed (1) |
| drop `hasPremium` on event create | killed (1) |
| **open `events` read to any signed-in user** | **survived**: no read test for events |
| **let `view` delete places** (kid could delete Home) | **survived**: no kid/view delete test |

  - Missing rules cases: a kid device reading the map, days, events and places; a shift-only carer off
    shift; a pre-ADR-0003 helper with no grant; an event read by a helper without the grant.
- **Functions:** no test for `leaveHousehold` + location (H3), a repeat after a missed exit (H4), the
  `places` switch off, or quiet hours for places.

## Godfather memory vs code

1. **Notifications ADR-0004 is `proposed`, but the code ships it.** Live-location ADR-0006 (accepted)
   still says "the lock screen says only 'An arrival' and names nobody". There is no supersede or amend
   link, so the accepted record contradicts the code.
2. **The live-location overview is wrong in several places:**
   - It cites `[[ADR-0003]]` (superseded) for "only a member's own device starts…"; that should be ADR-0008.
   - "Stops on … sign-out" is false on Android (C1).
   - "Premium lapsing stops it on the device too (AlwaysSharingGuard)" is false on kid devices (H7).
   - The removal constraint omits `leaveHousehold` (H3).
   - Delivery says the Dart screens have "four states and dark at 200% for each new screen", which is partly false.
3. **Not updated, as flagged:**
   - The subscriptions overview's `PremiumFeature` table has no `familyLocation`.
   - The household overview's area contract still lists ten areas: no `location` row, no ADR-0008 in
     its decisions table, and "a new area is an ADR amendment to ADR-0003's table" was not done.
   - The notifications overview has no `places` category, `whereWeAre` target, `nestprep_places`
     channel or ADR-0004. It still says "a lock screen carries counts and kinds only — never a name".
4. **Smaller slips:**
   - Accounts ADR-0010's title reads "ADR-0007".
   - The phase doc says 46 XCTests and the overview 49.
   - ADR-0005 says the Android heartbeat renews the lease and battery but never mentions that it sends a stale fix (H10).

---

## Verified fine

- **Rules:**
  - `isOwnMember` on the path is the only write path for live, days and events; an admin can only delete.
  - Continuous needs `mode == 'continuous'` + `hasPremium` + under 25 h; a window is under 4 h, free,
    and a doc with no `mode` is a window.
  - No expiry check in any read rule; reads use `canView(location)`.
  - Places: `canEdit` + `hasPremium` to write, delete without premium, and the shape checks
    (name 1–40, int radius 75–500, icon enum, alerts map).
  - Events: no update; `isServerTime` on `at`; expiry 29–31 days.
  - `isGrant` includes `location`; `notificationsCategoriesAreValid` includes `places`.
  - `firestore.rules`/`storage.rules` are up to date with the partials (`rules:check`).
- **Payloads:**
  - Android, iOS and Dart key sets match each rule's `hasOnly`.
  - `point` is a GeoPoint; `accuracyMetres` and `batteryPercent` are ints (iOS leaves battery out when −1).
  - Server timestamps where the rules need them; a 24 h lease; 30-day expiry.
  - Day docs are a merge `set` with `arrayUnion`, at most 120 a write, so midnight in the household zone creates the next day correctly.
  - The 12 s live floor and the 30 s day spacing are measured from the ack; one write in flight per
    kind; the 3,000 overflow is dropped locally without a loop.
- **Android platform:**
  - `foregroundServiceType="location"` and `startForeground(…, TYPE_LOCATION)`.
  - Mutable explicit PendingIntents for geofences and activity recognition.
  - Location is not one of Android 15's `BOOT_COMPLETED`-blocked types.
  - At most 99 places + the still fence.
  - Memory-only Firestore cache in `:location`; explicit `FirebaseApp` init there; no snapshot
    listeners in `:location`; the emulator host is applied before first use.
- **iOS platform:**
  - `CLLocationManager` and its delegate are created before `didFinishLaunching` returns.
  - The `BGTaskScheduler` id is registered and listed in the plist.
  - Background modes are `location`, `fetch`; Always, When-In-Use and Motion purpose strings are present.
  - Still region + 19 places = 20; stale regions are removed; every callback lands on the main queue;
    the uid is compared on every pump; the trail file write is atomic.
- **Functions:**
  - `notifyPlaceEvent` excludes the mover and uses `canSee(location)`, so a helper with `none` gets nothing.
  - Family get named text; everyone else gets "An arrival"; push data is ids only; inbox ids are deterministic.
  - `removeMember` deletes `memberLocations` in the transaction and `recursiveDelete`s the trail.
  - `leaveErasing` deletes the trail; the export has `whereYouHaveBeen`.
  - `location` is added to `AREAS`, `AREA_LEVELS`, `ROLE_DEFAULTS` and the zod grant.
  - The `places` category, channel and target are mirrored in Dart.
- **Dart:**
  - The window and place writes match the rules.
  - Premium UI gates use `ensurePremium`.
  - The guard checks `isKnown`, so it doesn't stop sharing while the entitlement is loading.
  - Reads are bounded (live 50, places 30, a day is one doc plus bounded events).
  - The disclosure comes before every OS prompt and needs an explicit Continue.
  - The map is behind `NESTPREP_MAPS`; the location strings are in `location_copy.dart`.
- **Secrets:**
  - `app/android/maps.properties` and `app/ios/Flutter/Maps.xcconfig` are gitignored and untracked.
  - No Maps key in any tracked or untracked file or in the diff. (The `AIza…` in
    `hosting/src/connect-config.json` is the public Firebase web key from the assistants work, not location.)
- **Hosting:** `hosting/public` is up to date with the policy (`site:check`).

## Counts

Critical 2 · High 12 · Medium 23 · Low 10 groups · Godfather memory 4 groups (the gaps flagged in the brief confirmed).

---

## Addressed (2026-11-02, the authoring session)

**Fixed**
- **C1** — `SessionController(beforeSignOut:)` → `AlwaysSharing.stopBeforeSignOut` (window reporter + engine + pin, bounded); Android `SignOutWatch` in the main process plus an auth listener and per-write uid check in `:location`; iOS deletes the pin through the secondary app and stops on a nil/changed user. Test: `session_controller_test` (order), `always_sharing_test` (stopBeforeSignOut).
- **C2** — iOS protected-data guard removed; nil user is "waiting" only while protected data is unavailable.
- **H1** — only live-lane denials count (both engines); denied day/event writes dropped and logged; queued events pruned on `setPlaces`; places read natively on begin and heartbeat/lease refresh; a fresh engine's first pace denial is retried uncounted; iOS `alreadyExists` = success.
- **H2** — payloads built at send time; a denial of a write queued >5 min is never counted (both engines).
- **H3** — `leaveHousehold` calls `forgetWhereTheyWere` (pin, trail, `placeEvent` inbox items); `removeMember` and `leaveErasing` too. Emulator test in `membership.test.ts`.
- **H4** — `lastPlaceEvents` is `{kind, at}`; `isNews`: 2-minute flap window, 30-minute repeat window. Unit tests; emulator test "an arrival after a missed exit".
- **H5** — `AlwaysSharing.start` asks up to twice; Android confirmed two-step. Test with a fake sequence.
- **H6** — Android Pause notification action (label from Dart, `paused` reason); disclosure now says "even when the app is closed or not in use" and names the motion use; iOS background indicator on.
- **H7** — lifecycle observer moved into the app-wide `AlwaysSharing` (initial state from the binding); kid sheet passes places, shows Stop for an open window, has loading/error; engines read places natively. Tests in `always_sharing_guard_and_kid_test.dart`.
- **H8** — ticker republishes only while `AsyncData`. Test over 90 s after a failure. (The navigation test relied on the bug and was fixed.)
- **H9** — Android timers are `ELAPSED_REALTIME_WAKEUP` alarms; STILL ENTER → still; 60 s wakelock.
- **H10** — Android heartbeat takes a fresh fix or writes nothing; no fix older than 10 min is published; fences re-registered on `GEOFENCE_NOT_AVAILABLE` and providers-changed.
- **H11** — every halt and failed launch clears the native config; Dart `stop` always calls native `stop`.
- **H12** — Always is hidden while a window is open, and `start` stops the window reporter (pin kept).
- **M1** iOS never configures the default app; secondary app has its own App Check provider · **M2** resume on every callback · **M3** fix filtering and still-alarm arming · **M4** Always upgrade, Settings, reduced accuracy · **M5** dwell confirmed in a background task · **M7** crossings older than 15 min dropped (both) · **M8** flap window bounds a flapping fence · **M9** policy text corrected (kids see by default, legacy helpers, names inside the app, sign-out, leaving) · **M10** subcollections renamed `trailDays`/`placeEvents` (rules, Functions, Dart, native, TTL, fixture) · **M11** cost restated with rule reads in live-location ADR-0009 · **M12** start for another household deletes the old pin (both) · **M13** pin removal waits at most 4 s · **M14** guard stops post-frame, once, and only marks "refused" on success · **M15** `/where`, history and places are gated on the location grant · **M17** stop drains every batch within ~10 s (both) · **M18** exact alarms when allowed; FGS start refusal logged, config kept · **M19** POST_NOTIFICATIONS asked with background (Android 13+) · **M20** erasure, removal and leaving sweep the `placeEvent` inbox items naming the person · **M21** the cloud-demo seed no longer writes events (no real pushes) · **M22** place editor: retryable error, "place has gone", map follows "Use where I am", slider announces metres, name capped at 40 · **M23** history stops show the street.
- **Low** — Android unknown zone → device zone; `startForeground` before halt; iOS duplicate place ids; XCTest host no longer resumes a saved config; `StreetNames` no longer caches a failed lookup; map re-frames only when the path length changes; `notStarted` no longer shown as a permission refusal; map semantics label; stale `hasClaimed` comment.
- **Rules tests** — event reads (family yes, helper without grant and stranger no), `view` cannot delete or change places, kid device reads the map and places. Suite 1,198 green.
- **Godfather** — notifications ADR-0004 accepted; live-location ADR-0009 supersedes ADR-0004 and ADR-0006; overview, household, notifications and subscriptions overviews updated.

**Not done, and why**
- **M6** iOS lease renewal while still relies on `BGAppRefreshTask`; a silent-push keep-alive waits on APNs (Apple Developer Program).
- **M16** two sharing phones for one member: named as unsupported in ADR-0009.
- **Low** day rules do not validate each point's shape (the member's own data; the reader skips bad points); the live pace can be bypassed by delete+create or mode flips (only a runaway client is hurt); no fast-clock tolerance on the 4 h window.
- **Android App Check** in the `:location` process (Play Integrity) and **iOS App Attest/DeviceCheck registration** in the console — before App Check enforcement for Firestore.
- **Tests still missing**: Android `LocationService`/`FirestoreStore` and iOS `LocationEngine`/`FirebaseLink` integration (need a device); the map itself (a platform view).
