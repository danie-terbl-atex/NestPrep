part of 'app_failure.dart';

// ---- nanny hub (nanny-hub ADR-0002, ADR-0003) ----

/// Why something in the nanny hub did not happen. The first four are a
/// `reason` `endNannyShift` puts in its error's details — the server's
/// `NANNY_REFUSALS` is the other half, and a test reads both. The rest are the
/// phone's own: a photo that could not be taken or read, a call that nothing
/// on the phone would place. Membership refusals stay `HouseholdProblem`.
enum NannyHubProblem {
  /// The household's `nannyHub` grant is not `edit` for this person.
  hubNotShared,

  /// The shift was never there, or is gone.
  shiftNotFound,

  /// Somebody else ended the shift a moment ago.
  shiftAlreadyEnded,

  /// A carer ends their own shift; this one is somebody else's.
  notYourShift,

  /// The picked photo is not a picture the app can read.
  photoUnreadable,

  /// Even compressed, the photo is past what the rules keep.
  photoTooLarge,

  /// The camera or the photo library would not open.
  cameraUnavailable,

  /// Nothing on the phone would place the call.
  cannotCall,

  /// Only a carer can be kept to their booked shifts (nanny-hub ADR-0006).
  notACarer,

  /// The phone would not keep the hub's photos for offline — out of space,
  /// or its own folder refused (nanny-hub ADR-0007).
  cannotSaveOffline,

  /// A house code is only shown while a shift the viewer is booked on is
  /// open (nanny-hub ADR-0006).
  codesClosed,
}

final class NannyHubFailure extends AppFailure {
  const NannyHubFailure(this.problem);

  final NannyHubProblem problem;
}
