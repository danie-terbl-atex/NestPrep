/// Every V2 capability that can be switched off without a migration
/// (foundation ADR-0014), and the field that switches it in
/// `appConfig/flags`.
///
/// One enum for the whole app, so there is one place to see what is
/// switchable. The Functions read the same fields from
/// `functions/src/shared/feature_flags.ts`, and `feature_flags.test.ts` there
/// reads this file and fails if the two lists differ.
///
/// A V2 feature adds one value here, one field on the server list, and reads
/// it through `FeatureFlagsController.isOn`.
enum FeatureFlag {
  /// Share one document by an expiring link (documents ADR-0006).
  documentShareLinks('documentShareLinks'),

  /// Keep chosen documents on the phone, encrypted (documents ADR-0007).
  documentOfflineCopies('documentOfflineCopies'),

  /// Snap a school letter into proposed events (calendar ADR-0005).
  snapSchoolLetter('snapSchoolLetter'),

  /// The shared week: who is handling what (calendar ADR-0006).
  mentalLoadView('mentalLoadView'),

  /// Snap a shopping list onto the grocery list — premium (list-scan
  /// ADR-0001).
  snapShoppingList('snapShoppingList'),

  /// A child in two homes: shared schedules and handovers (household
  /// ADR-0004).
  coParenting('coParenting'),

  // ---- nanny hub V2 (nanny-hub ADR-0004 to ADR-0007) ----

  /// A carer's photos to the parents during a shift (nanny-hub ADR-0004).
  nannyPhotoUpdates('nannyPhotoUpdates'),

  /// Who may collect each child, and the school run (nanny-hub ADR-0005).
  nannyPickups('nannyPickups'),

  /// Booked shifts, shift-only carers and the house codes (nanny-hub
  /// ADR-0006). The rules enforce a shift-only carer's window whatever this
  /// says; the switch only hides the screens that set one up.
  nannyShiftOnly('nannyShiftOnly'),

  /// The emergency sheet and child cards saved for no signal (nanny-hub
  /// ADR-0007).
  nannyOffline('nannyOffline'),

  /// Give a month, get a month (subscriptions ADR-0002).
  referralRewards('referralRewards'),

  /// Claiming Premium from a frame order or a gift, and proving an email for
  /// it (subscriptions ADR-0003, ADR-0004).
  premiumVouchers('premiumVouchers'),

  // ---- lunch-box V2 (lunch-box ADR-0005 to ADR-0007) ----

  /// What is in the house, and planning the week from it (lunch-box
  /// ADR-0005).
  lunchPantry('lunchPantry'),

  /// What a box and a week cost, a weekly budget and cheaper swaps — premium
  /// as well (lunch-box ADR-0006).
  lunchBudget('lunchBudget'),

  /// A child choosing their own box from options a parent approved
  /// (lunch-box ADR-0007). The rules hold a kid to the approved options
  /// whatever this says; the switch only hides the screens.
  lunchKidPicks('lunchKidPicks'),

  // ---- home care V2 (home-care ADR-0004 to ADR-0006) ----

  /// Recurring checklists per room, and the helper's today's rooms
  /// (home-care ADR-0004).
  homeCareRoutines('homeCareRoutines'),

  /// Each product's stock level, and a low one onto the grocery list
  /// (home-care ADR-0005).
  homeCareStock('homeCareStock'),

  /// The helper's own language for her jobs, and read-aloud (home-care
  /// ADR-0006).
  homeCareHelperLanguage('homeCareHelperLanguage'),

  /// A helper clocks in and out, in the app and at a frame (home-care
  /// ADR-0007).
  homeCareShifts('homeCareShifts'),

  // ---- plan my week with AI (lunch-box ADR-0011) ----

  /// One tap plans the week's lunches, dinners and the shopping list —
  /// premium as well, and counted against the AI cap.
  planMyWeek('planMyWeek'),

  // ---- groceries: Checkers (the Checkers build contract) ----

  /// Checkers for builds up to 0.9.0 (14), which the testers still run, and
  /// for the Functions and the frames. No screen in this build reads it:
  /// [checkersShop] decides whether Checkers is offered (shops ADR-0002).
  addToCheckers('addToCheckers'),

  /// Whether Checkers is offered at all: matches, the member's own link, the
  /// cart and its mark, everywhere (shops ADR-0002).
  checkersShop('checkersShop'),

  // ---- lunch box: Pick n Pay (add-to-pnp ADR-0001) ----

  /// *Plan my week* at Pick n Pay, linking a member's own Pick n Pay
  /// account, and pushing the week's basket into their own cart.
  addToPnp('addToPnp'),

  // ---- groceries: Woolworths (add-to-woolworths ADR-0001) ----

  /// Woolworths for builds up to 0.9.0 (14), the Functions and the frames,
  /// as [addToCheckers] is. [woolworthsShop] decides in this build.
  addToWoolworths('addToWoolworths'),

  /// Whether Woolworths is offered at all, as [checkersShop] is for Checkers
  /// (shops ADR-0002).
  woolworthsShop('woolworthsShop'),

  // ---- photo frames (photo-frames ADR-0001) ----

  /// Linking a wall photo frame running NestPrep Home to the household.
  photoFrames('photoFrames'),

  /// NestPrep in Claude and ChatGPT: a member connects an assistant that adds
  /// events and grocery items as them (assistants ADR-0001).
  assistants('assistants'),

  /// A household's own recipes, typed, read from a page or from a photo —
  /// premium as well (recipes ADR-0007, ADR-0008).
  householdRecipes('householdRecipes'),

  avatars('avatars'),

  avatarCreations('avatarCreations'),

  /// Children's routines: a morning, afternoon and bedtime run of picture
  /// steps per child (kid-routines ADR-0001).
  kidRoutines('kidRoutines'),

  /// A new household starts with a few examples (household ADR-0010).
  starterContent('starterContent');

  const FeatureFlag(this.field);

  /// Whether this switch stays off until the document turns it on (shops
  /// ADR-0002). Every other switch is on until the document says `false`; a
  /// shop waiting to go live must not show for the moment before the
  /// document has loaded, or for as long as it cannot be read.
  bool get waitsToGoLive => this == checkersShop || this == woolworthsShop;

  /// The boolean field in `appConfig/flags` that switches it.
  final String field;
}
