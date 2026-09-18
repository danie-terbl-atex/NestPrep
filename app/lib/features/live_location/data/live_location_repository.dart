import '../model/coordinates.dart';
import '../model/member_location.dart';

/// What the live-location feature needs from Firestore (live-location
/// ADR-0001).
///
/// One document per member, keyed by the member id, so a member writes only
/// their own and an unclaimed profile has no writer at all. There is no
/// history: reporting overwrites, and stopping deletes.
abstract interface class LiveLocationRepository {
  /// Everybody in the household who has a position document right now. It is
  /// not filtered by the window: a document whose `sharingUntil` has passed is
  /// read as *not sharing* on the client, because a rule that compared
  /// `request.time` to document data would fail the whole listener the moment
  /// any one member's window closed (live-location ADR-0001).
  Stream<List<MemberLocation>> watchLocations(String householdId);

  /// Reports [memberId]'s own position, for a share ending at [sharingUntil].
  /// The server stamps the time; the rules refuse a window further away than
  /// [longestShare] and refuse the write once the window has passed.
  Future<void> report({
    required String householdId,
    required String memberId,
    required Coordinates at,
    required int accuracyMetres,
    required DateTime sharingUntil,
  });

  /// Stops sharing by removing the document. Nothing is left for the household
  /// to read, which is what *stop* has to mean (live-location ADR-0002).
  Future<void> stopSharing({
    required String householdId,
    required String memberId,
  });

  /// How many position documents are read at once. A household has at most a
  /// handful; this is the bound that stops a bug making it unbounded
  /// (`BE-08`).
  static const locationLimit = 50;

  /// The longest window a member may open, mirrored in `firestore.rules`. A
  /// bound only the client keeps is not a bound (`BE-20`), so the number is
  /// here *and* there, and the rules tests are what prove they agree.
  static const longestShare = Duration(hours: 4);

  /// The shortest gap between two writes from one device. At walking pace the
  /// 100 m distance filter fires about every 72 seconds and at driving pace
  /// every 6 — this is what makes both of them 40 writes an hour
  /// (live-location ADR-0001).
  static const reportEvery = Duration(seconds: 90);

  /// How far a device must move before the platform offers a new fix. It is
  /// the setting that does the work: a member who is not moving costs one
  /// write for the whole window.
  static const moveBeforeReporting = 100;
}
