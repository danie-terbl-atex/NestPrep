import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'cleaning_job.dart';
import 'job_step.dart';

/// What is missing before a job can be assigned — each one a field the form
/// points at, and each one something the rules would refuse too.
enum JobDetailsProblem { noTitle, noRoom, noHelper, noSteps }

/// The part of a job a parent writes and can change while it is still with
/// the helper: everything but the photos, the ticks and the status
/// (home-care ADR-0001). The composer and the edit sheet both fill one.
@immutable
final class JobDetails {
  const JobDetails({
    required this.dueDate,
    this.title = '',
    this.roomId,
    this.helperId,
    this.note,
    this.productIds = const [],
    this.steps = const [],
  });

  factory JobDetails.of(CleaningJob job) => JobDetails(
    title: job.title,
    roomId: job.roomId,
    helperId: job.helperId,
    dueDate: job.dueDate,
    note: job.note,
    productIds: job.productIds,
    steps: job.steps,
  );

  final String title;
  final String? roomId;
  final String? helperId;
  final CalendarDate dueDate;
  final String? note;
  final List<String> productIds;
  final List<JobStep> steps;

  /// The title and note as they will be stored: trimmed, and an empty note
  /// is no note.
  String get cleanTitle => title.trim();
  String? get cleanNote {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  List<JobDetailsProblem> get problems => [
    if (cleanTitle.isEmpty) JobDetailsProblem.noTitle,
    if (roomId == null) JobDetailsProblem.noRoom,
    if (helperId == null) JobDetailsProblem.noHelper,
    if (steps.isEmpty) JobDetailsProblem.noSteps,
  ];

  bool get isComplete => problems.isEmpty;

  bool get canAddStep => steps.length < CleaningJob.stepLimit;

  /// A new step at the end, with an id no other step in this job has.
  JobDetails withStepAdded(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !canAddStep) return this;
    final used = steps.map((step) => step.id).toSet();
    var next = steps.length + 1;
    while (used.contains('s$next')) {
      next++;
    }
    return copyWith(
      steps: [
        ...steps,
        JobStep(id: 's$next', text: trimmed),
      ],
    );
  }

  JobDetails withoutStep(String stepId) => copyWith(
    steps: [
      for (final s in steps)
        if (s.id != stepId) s,
    ],
  );

  JobDetails withProductToggled(String productId) => copyWith(
    productIds: productIds.contains(productId)
        ? [
            for (final id in productIds)
              if (id != productId) id,
          ]
        : productIds.length < CleaningJob.productLimit
        ? [...productIds, productId]
        : productIds,
  );

  JobDetails copyWith({
    String? title,
    String? roomId,
    String? helperId,
    CalendarDate? dueDate,
    String? note,
    List<String>? productIds,
    List<JobStep>? steps,
  }) => JobDetails(
    title: title ?? this.title,
    roomId: roomId ?? this.roomId,
    helperId: helperId ?? this.helperId,
    dueDate: dueDate ?? this.dueDate,
    note: note ?? this.note,
    productIds: productIds ?? this.productIds,
    steps: steps ?? this.steps,
  );
}
