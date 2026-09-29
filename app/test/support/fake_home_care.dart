import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/home_care/data/cleaning_job_repository.dart';
import 'package:nestprep/features/home_care/data/home_care_library_repository.dart';
import 'package:nestprep/features/home_care/data/job_photo_store.dart';
import 'package:nestprep/features/home_care/data/photo_compressor.dart';
import 'package:nestprep/features/home_care/data/photo_source.dart';
import 'package:nestprep/features/home_care/model/cleaning_job.dart';
import 'package:nestprep/features/home_care/model/compressed_photo.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/model/job_details.dart';
import 'package:nestprep/features/home_care/model/job_event.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/room_kind.dart';
import 'package:nestprep/features/home_care/model/spot_mark.dart';
import 'package:nestprep/features/home_care/state/photo_intake.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Everything a write was asked to do, in order, as `(method, arguments)` —
/// so a test asserts what a tap asked the backend for (`FE-20`).
typedef Recorded = (String, Map<String, Object?>);

mixin _Recorder {
  final writes = <Recorded>[];

  /// Set to make the next write fail the way a rules denial does.
  AppFailure? failWritesWith;

  Future<void> record(String method, Map<String, Object?> arguments) async {
    final failure = failWritesWith;
    if (failure != null) {
      failWritesWith = null;
      throw failure;
    }
    writes.add((method, arguments));
  }

  Iterable<String> get methods => writes.map((write) => write.$1);
}

/// The jobs and their history, driven by hand.
final class FakeCleaningJobRepository
    with _Recorder
    implements CleaningJobRepository {
  final _jobs = StreamController<List<CleaningJob>>.broadcast();
  final _events = StreamController<List<JobEvent>>.broadcast();

  /// Each job read's scope: null for every job, else the helper asked for.
  final jobsAskedFor = <String?>[];

  void emitJobs(List<CleaningJob> jobs) => _jobs.add(jobs);
  void emitEvents(List<JobEvent> events) => _events.add(events);
  void failJobsWith(Object error) => _jobs.addError(error);
  void failEventsWith(Object error) => _events.addError(error);

  Future<void> close() async {
    await _jobs.close();
    await _events.close();
  }

  @override
  Stream<List<CleaningJob>> watchJobs(String householdId, {String? helperId}) {
    jobsAskedFor.add(helperId);
    return _jobs.stream;
  }

  @override
  Stream<List<JobEvent>> watchEvents({
    required String householdId,
    required String jobId,
  }) => _events.stream;

  var _ids = 0;

  @override
  String newJobId(String householdId) => 'new-job-${++_ids}';

  @override
  Future<void> createJob({
    required String householdId,
    required String jobId,
    required JobDetails details,
    required JobPhoto beforePhoto,
    required List<SpotMark> marks,
    required String createdBy,
  }) => record('createJob', {
    'jobId': jobId,
    'details': details,
    'beforePhoto': beforePhoto,
    'marks': marks,
    'createdBy': createdBy,
  });

  @override
  Future<void> updateDetails({
    required String householdId,
    required CleaningJob job,
    required JobDetails details,
  }) => record('updateDetails', {'jobId': job.id, 'details': details});

  @override
  Future<void> setDoneSteps({
    required String householdId,
    required CleaningJob job,
    required List<String> doneStepIds,
    required String by,
  }) => record('setDoneSteps', {
    'jobId': job.id,
    'doneStepIds': doneStepIds,
    'by': by,
  });

  @override
  Future<void> handIn({
    required String householdId,
    required CleaningJob job,
    required JobPhoto afterPhoto,
    required String by,
  }) => record('handIn', {'jobId': job.id, 'afterPhoto': afterPhoto, 'by': by});

  @override
  Future<void> approve({
    required String householdId,
    required CleaningJob job,
    required String by,
  }) => record('approve', {'jobId': job.id, 'by': by});

  @override
  Future<void> sendBack({
    required String householdId,
    required CleaningJob job,
    required String note,
    required String by,
  }) => record('sendBack', {'jobId': job.id, 'note': note, 'by': by});

  @override
  Future<void> deleteJob({
    required String householdId,
    required String jobId,
  }) => record('deleteJob', {'jobId': jobId});
}

/// The rooms and the product library, driven by hand.
final class FakeHomeCareLibraryRepository
    with _Recorder
    implements HomeCareLibraryRepository {
  final _rooms = StreamController<List<HomeCareRoom>>.broadcast();
  final _products = StreamController<List<HomeCareProduct>>.broadcast();

  void emitRooms(List<HomeCareRoom> rooms) => _rooms.add(rooms);
  void emitProducts(List<HomeCareProduct> products) => _products.add(products);
  void failRoomsWith(Object error) => _rooms.addError(error);

  Future<void> close() async {
    await _rooms.close();
    await _products.close();
  }

  @override
  Stream<List<HomeCareRoom>> watchRooms(String householdId) => _rooms.stream;

  @override
  Stream<List<HomeCareProduct>> watchProducts(String householdId) =>
      _products.stream;

  @override
  Future<void> saveRoom({
    required String householdId,
    String? roomId,
    required String name,
    required RoomKind kind,
    required String createdBy,
  }) => record('saveRoom', {
    'roomId': roomId,
    'name': name,
    'kind': kind,
    'createdBy': createdBy,
  });

  @override
  Future<void> addRooms({
    required String householdId,
    required List<({String name, RoomKind kind})> rooms,
    required String createdBy,
  }) => record('addRooms', {'rooms': rooms, 'createdBy': createdBy});

  @override
  Future<void> deleteRoom({
    required String householdId,
    required String roomId,
  }) => record('deleteRoom', {'roomId': roomId});

  @override
  Future<void> saveProduct({
    required String householdId,
    required HomeCareProduct product,
  }) => record('saveProduct', {'product': product});

  @override
  Future<void> deleteProduct({
    required String householdId,
    required String productId,
  }) => record('deleteProduct', {'productId': productId});
}

/// The photos' bytes: what is stored, what was read, and a failure to hand
/// out on demand.
final class FakeJobPhotoStore with _Recorder implements JobPhotoStore {
  final stored = <String, Uint8List>{};

  /// Reads that fail, by photo id.
  final failReads = <String, AppFailure>{};

  /// Removes that fail, by photo id.
  final failRemoves = <String, AppFailure>{};

  @override
  Future<void> upload({
    required String householdId,
    required String jobId,
    required String photoId,
    required String uploaderUid,
    required CompressedPhoto photo,
  }) async {
    await record('upload', {
      'jobId': jobId,
      'photoId': photoId,
      'uploaderUid': uploaderUid,
    });
    stored['$jobId/$photoId'] = photo.bytes;
  }

  @override
  Future<Uint8List> read({
    required String householdId,
    required String jobId,
    required String photoId,
  }) async {
    final failure = failReads[photoId];
    if (failure != null) throw failure;
    return stored['$jobId/$photoId'] ?? Uint8List(0);
  }

  @override
  Future<void> remove({
    required String householdId,
    required String jobId,
    required String photoId,
  }) async {
    final failure = failRemoves[photoId];
    if (failure != null) throw failure;
    await record('remove', {'jobId': jobId, 'photoId': photoId});
  }
}

/// The camera: hands back whatever the test put in it, or nothing.
final class FakePhotoSource implements PhotoSource {
  Uint8List? next;
  AppFailure? failWith;
  final asked = <PhotoOrigin>[];

  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async {
    asked.add(origin);
    final failure = failWith;
    if (failure != null) throw failure;
    return next;
  }
}

/// A compressor that does no work: a test is about what the controller does
/// with a photo, and `photo_compressor_test.dart` is about compressing one.
final class FakePhotoCompressor implements PhotoCompressor {
  const FakePhotoCompressor();

  @override
  Future<CompressedPhoto> compress(Uint8List original) async =>
      CompressedPhoto(bytes: original, width: 400, height: 300);
}

/// The two above, as the intake the controllers are given.
PhotoIntake fakePhotoIntake(FakePhotoSource source) =>
    PhotoIntake(source: source, compressor: const FakePhotoCompressor());
