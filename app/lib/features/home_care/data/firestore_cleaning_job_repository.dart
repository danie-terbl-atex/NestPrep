import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/cleaning_job.dart';
import '../model/job_details.dart';
import '../model/job_event.dart';
import '../model/job_photo.dart';
import '../model/job_status.dart';
import '../model/spot_mark.dart';
import 'cleaning_job_repository.dart';

final class FirestoreCleaningJobRepository implements CleaningJobRepository {
  FirestoreCleaningJobRepository(this._firestore);

  static const householdsPath = 'households';
  static const jobsPath = 'homeCareJobs';
  static const eventsPath = 'events';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _rawJobs(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(jobsPath);

  CollectionReference<CleaningJob> _jobs(String householdId) => typedCollection(
    _rawJobs(householdId),
    fromJson: CleaningJob.fromJson,
    toJson: (job) => job.toJson(),
  );

  CollectionReference<JobEvent> _events(String householdId, String jobId) =>
      typedCollection(
        _rawJobs(householdId).doc(jobId).collection(eventsPath),
        fromJson: JobEvent.fromJson,
        toJson: (event) => event.toJson(),
      );

  @override
  Stream<List<CleaningJob>> watchJobs(String householdId, {String? helperId}) =>
      (helperId == null
              ? _jobs(householdId)
              : _jobs(householdId).where('helperId', isEqualTo: helperId))
          .orderBy('dueDate', descending: true)
          .limit(CleaningJobRepository.jobLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<JobEvent>> watchEvents({
    required String householdId,
    required String jobId,
  }) => _events(householdId, jobId)
      .limit(CleaningJobRepository.eventLimit)
      .snapshots()
      .map(
        (snapshot) =>
            [for (final doc in snapshot.docs) doc.data()]
              ..sort((a, b) => a.revision.compareTo(b.revision)),
      )
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  String newJobId(String householdId) => _rawJobs(householdId).doc().id;

  @override
  Future<void> createJob({
    required String householdId,
    required String jobId,
    required JobDetails details,
    required JobPhoto beforePhoto,
    required List<SpotMark> marks,
    required String createdBy,
  }) {
    final job = CleaningJob(
      id: jobId,
      title: details.cleanTitle,
      roomId: details.roomId ?? '',
      helperId: details.helperId ?? '',
      dueDate: details.dueDate,
      note: details.cleanNote,
      productIds: details.productIds,
      steps: details.steps,
      beforePhoto: beforePhoto,
      marks: marks,
      createdBy: createdBy,
    );
    final batch = _firestore.batch()..set(_jobs(householdId).doc(jobId), job);
    _logInto(batch, householdId, job, JobStatus.assigned, createdBy);
    return _guarded(batch.commit);
  }

  @override
  Future<void> updateDetails({
    required String householdId,
    required CleaningJob job,
    required JobDetails details,
  }) => _guarded(
    () => _rawJobs(householdId).doc(job.id).update({
      'title': details.cleanTitle,
      'roomId': details.roomId,
      'helperId': details.helperId,
      'dueDate': details.dueDate.iso,
      'note': details.cleanNote,
      'productIds': details.productIds,
      'steps': [for (final step in details.steps) step.toJson()],
      'doneStepIds': [
        for (final step in details.steps)
          if (job.isStepDone(step.id)) step.id,
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> setDoneSteps({
    required String householdId,
    required CleaningJob job,
    required List<String> doneStepIds,
    required String by,
  }) {
    final starts = job.status != JobStatus.inProgress;
    return _change(
      householdId,
      job,
      fields: {'doneStepIds': doneStepIds},
      movesTo: starts ? JobStatus.inProgress : null,
      by: by,
    );
  }

  @override
  Future<void> handIn({
    required String householdId,
    required CleaningJob job,
    required JobPhoto afterPhoto,
    required String by,
  }) => _change(
    householdId,
    job,
    fields: {
      'doneStepIds': [for (final step in job.steps) step.id],
      'afterPhoto': afterPhoto.toJson(),
    },
    movesTo: JobStatus.submitted,
    by: by,
  );

  @override
  Future<void> approve({
    required String householdId,
    required CleaningJob job,
    required String by,
  }) => _change(householdId, job, movesTo: JobStatus.approved, by: by);

  @override
  Future<void> sendBack({
    required String householdId,
    required CleaningJob job,
    required String note,
    required String by,
  }) => _change(
    householdId,
    job,
    fields: {'reviewNote': note},
    movesTo: JobStatus.sentBack,
    by: by,
    note: note,
  );

  @override
  Future<void> deleteJob({
    required String householdId,
    required String jobId,
  }) async {
    final events = _rawJobs(householdId).doc(jobId).collection(eventsPath);
    try {
      final history = await events
          .limit(CleaningJobRepository.eventLimit)
          .get();
      final batch = _firestore.batch();
      for (final event in history.docs) {
        batch.delete(event.reference);
      }
      batch.delete(_rawJobs(householdId).doc(jobId));
      await batch.commit();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  /// One write to a job. A status change bumps the revision and writes the
  /// history event named for it in the same batch (home-care ADR-0001).
  Future<void> _change(
    String householdId,
    CleaningJob job, {
    Map<String, Object?> fields = const {},
    JobStatus? movesTo,
    required String by,
    String? note,
  }) {
    final batch = _firestore.batch();
    final revision = movesTo == null ? job.revision : job.revision + 1;
    batch.update(_rawJobs(householdId).doc(job.id), {
      ...fields,
      if (movesTo != null) 'status': movesTo.name,
      if (movesTo != null) 'revision': revision,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (movesTo != null) {
      _logInto(
        batch,
        householdId,
        job.copyWith(revision: revision),
        movesTo,
        by,
        note: note,
      );
    }
    return _guarded(batch.commit);
  }

  void _logInto(
    WriteBatch batch,
    String householdId,
    CleaningJob job,
    JobStatus status,
    String by, {
    String? note,
  }) {
    final id = '${job.revision}';
    batch.set(
      _events(householdId, job.id).doc(id),
      JobEvent(id: id, status: status, by: by, note: note),
    );
  }

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
