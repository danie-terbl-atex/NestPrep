import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/nanny_hub/data/booking_repository.dart';
import 'package:nestprep/features/nanny_hub/data/cache_warmer.dart';
import 'package:nestprep/features/nanny_hub/data/house_code_repository.dart';
import 'package:nestprep/features/nanny_hub/data/nanny_hub_repository.dart';
import 'package:nestprep/features/nanny_hub/data/offline_shelf.dart';
import 'package:nestprep/features/nanny_hub/data/photo_update_repository.dart';
import 'package:nestprep/features/nanny_hub/model/house_code.dart';
import 'package:nestprep/features/nanny_hub/model/photo_update.dart';
import 'package:nestprep/features/nanny_hub/model/shift_booking.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// A shift's photo updates, driven by hand (nanny-hub ADR-0004).
final class FakePhotoUpdateRepository implements PhotoUpdateRepository {
  final updates = StreamController<List<PhotoUpdate>>.broadcast();
  final sent = <PhotoUpdateWrite>[];
  final removed = <String>[];
  AppFailure? failWritesWith;

  /// Held open until the test completes it, to catch a second tap.
  Completer<void>? gate;

  @override
  Stream<List<PhotoUpdate>> watchUpdates({
    required String householdId,
    required String shiftId,
  }) => updates.stream;

  @override
  Future<void> send(PhotoUpdateWrite write) async {
    await gate?.future;
    final failure = failWritesWith;
    if (failure != null) throw failure;
    sent.add(write);
  }

  @override
  Future<void> remove({
    required String householdId,
    required String shiftId,
    required String updateId,
  }) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    removed.add(updateId);
  }

  Future<void> close() => updates.close();
}

/// Booked shifts and passes, driven by hand (nanny-hub ADR-0006).
final class FakeBookingRepository implements BookingRepository {
  final bookings = StreamController<List<ShiftBooking>>.broadcast();
  final booked = <BookingDraft>[];
  final cancelled = <String>[];

  /// Every pass written, as the booking id it named, in order.
  final passes = <String>[];

  /// What the last `watchUpcoming` asked for: a carer's own, or everybody's.
  String? askedForCarer;
  AppFailure? failWritesWith;
  AppFailure? failPassesWith;

  @override
  Stream<List<ShiftBooking>> watchUpcoming(
    String householdId, {
    required DateTime from,
    String? carerMemberId,
  }) {
    askedForCarer = carerMemberId;
    return bookings.stream;
  }

  @override
  Future<void> book(BookingDraft draft) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    booked.add(draft);
  }

  @override
  Future<void> cancel(String householdId, ShiftBooking booking) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    cancelled.add(booking.id);
  }

  @override
  Future<void> savePass(String householdId, ShiftBooking booking) async {
    final failure = failPassesWith;
    if (failure != null) throw failure;
    passes.add(booking.id);
  }

  Future<void> close() => bookings.close();
}

/// The house codes, as the server would answer them.
final class FakeHouseCodeRepository implements HouseCodeRepository {
  List<HouseCode> codes = const [];

  /// Set to answer the next fetches the way the rules or the network would.
  AppFailure? failFetchWith;
  AppFailure? failWritesWith;
  var fetches = 0;
  final writes = <(String, HouseCodeDraft?)>[];

  @override
  Future<List<HouseCode>> fetch(String householdId) async {
    fetches++;
    final failure = failFetchWith;
    if (failure != null) throw failure;
    return codes;
  }

  @override
  Future<void> add(AuthoredBy by, HouseCodeDraft draft) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    writes.add(('add', draft));
  }

  @override
  Future<void> update(
    String householdId,
    String codeId,
    HouseCodeDraft draft,
  ) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    writes.add(('update:$codeId', draft));
  }

  @override
  Future<void> remove(String householdId, String codeId) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    writes.add(('remove:$codeId', null));
  }
}

/// The server reads that fill Firestore's cache, answering the photo ids a
/// test chooses.
final class FakeCacheWarmer implements CacheWarmer {
  Set<String> photoIds = const {};
  AppFailure? failWith;
  final requests = <WarmRequest>[];

  /// Held open until the test completes it, to see "saving".
  Completer<void>? gate;

  @override
  Future<Set<String>> warm(WarmRequest request) async {
    requests.add(request);
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return photoIds;
  }
}

/// The phone's own shelf, in memory.
final class FakeOfflineShelf implements OfflineShelf {
  final photos = <String, Uint8List>{};
  final stamps = <String, DateTime>{};
  final cleared = <String>[];
  AppFailure? failWith;

  String _key(String householdId, String photoId) => '$householdId/$photoId';

  @override
  Future<Uint8List?> readPhoto({
    required String householdId,
    required String photoId,
  }) async {
    final failure = failWith;
    if (failure != null) throw failure;
    return photos[_key(householdId, photoId)];
  }

  @override
  Future<bool> hasPhoto({
    required String householdId,
    required String photoId,
  }) async => photos.containsKey(_key(householdId, photoId));

  @override
  Future<void> keepPhoto({
    required String householdId,
    required String photoId,
    required Uint8List jpeg,
  }) async {
    final failure = failWith;
    if (failure != null) throw failure;
    photos[_key(householdId, photoId)] = jpeg;
  }

  @override
  Future<DateTime?> savedAt(String householdId) async => stamps[householdId];

  @override
  Future<void> markSaved(String householdId, DateTime at) async {
    final failure = failWith;
    if (failure != null) throw failure;
    stamps[householdId] = at;
  }

  @override
  Future<void> clear(String householdId) async {
    cleared.add(householdId);
    photos.removeWhere((key, _) => key.startsWith('$householdId/'));
    stamps.remove(householdId);
  }
}
