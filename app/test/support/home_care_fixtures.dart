import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:nestprep/features/home_care/model/cleaning_job.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/model/job_photo.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/model/job_step.dart';
import 'package:nestprep/features/home_care/model/product_kind.dart';
import 'package:nestprep/features/home_care/model/room_kind.dart';
import 'package:nestprep/features/home_care/model/spot_mark.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'household_fixtures.dart';

/// The Parkers' home care: a kitchen and a bathroom, bleach and a glass
/// cleaner with ammonia in it — the pair that must never meet — and jobs for
/// Thandi, the helper, in every status.
abstract final class HomeCareFixtures {
  static const kitchen = HomeCareRoom(
    id: 'kitchen',
    name: 'Kitchen',
    kind: RoomKind.kitchen,
    createdBy: Fixtures.samMemberId,
  );

  static const bathroom = HomeCareRoom(
    id: 'bathroom',
    name: 'Bathroom',
    kind: RoomKind.bathroom,
    createdBy: Fixtures.samMemberId,
  );

  static const bleach = HomeCareProduct(
    id: 'jik',
    name: 'Jik',
    kind: ProductKind.bleach,
    whereKept: 'Under the sink',
    keepFromChildren: true,
    createdBy: Fixtures.samMemberId,
  );

  static const glassCleaner = HomeCareProduct(
    id: 'windolene',
    name: 'Window spray',
    kind: ProductKind.ammonia,
    whereKept: 'Laundry cupboard',
    createdBy: Fixtures.samMemberId,
  );

  static const soap = HomeCareProduct(
    id: 'sunlight',
    name: 'Sunlight liquid',
    kind: ProductKind.dishSoap,
    createdBy: Fixtures.samMemberId,
  );

  static const steps = [
    JobStep(id: 's1', text: 'Open a window'),
    JobStep(id: 's2', text: 'Spray and leave for five minutes'),
    JobStep(id: 's3', text: 'Wipe clean'),
  ];

  static CleaningJob job({
    String id = 'oven',
    String title = 'Grease on the oven door',
    JobStatus status = JobStatus.assigned,
    List<String> doneStepIds = const [],
    List<String> productIds = const ['jik'],
    String helperId = Fixtures.thandiMemberId,
    int revision = 0,
    JobPhoto? afterPhoto,
    String? reviewNote,
    CalendarDate? dueDate,
  }) => CleaningJob(
    id: id,
    title: title,
    roomId: kitchen.id,
    helperId: helperId,
    dueDate: dueDate ?? CalendarDate(2099, 10, 2),
    productIds: productIds,
    steps: steps,
    doneStepIds: doneStepIds,
    beforePhoto: const JobPhoto(photoId: 'before', width: 400, height: 300),
    marks: [circleRoundTheSpot],
    afterPhoto: afterPhoto,
    status: status,
    reviewNote: reviewNote,
    revision: revision,
    createdBy: Fixtures.samMemberId,
  );

  /// A circle drawn round the stain the review press paints, where a parent
  /// would draw it.
  static final circleRoundTheSpot = SpotMark(
    points: [
      for (var step = 0; step <= 24; step++) ...[
        0.64 + 0.17 * math.cos(step * math.pi / 12),
        0.44 + 0.23 * math.sin(step * math.pi / 12),
      ],
    ],
  );

  /// A job Thandi handed in, waiting for a parent.
  static CleaningJob handedIn() => job(
    status: JobStatus.submitted,
    doneStepIds: const ['s1', 's2', 's3'],
    revision: 2,
    afterPhoto: const JobPhoto(photoId: 'after-2', width: 300, height: 400),
  );

  /// Thandi, a helper holding only `homeCare: own` — her defaults.
  static HouseholdView helperView() =>
      Fixtures.helperView(AccessDefaults.helper);

  /// Thandi, allowed to look at every job but change none.
  static HouseholdView lookingHelperView() => Fixtures.helperView(
    AccessDefaults.helper.withLevel(HouseholdArea.homeCare, AccessLevel.view),
  );

  /// Thandi, with no home care at all.
  static HouseholdView noCleaningView() => Fixtures.helperView(
    AccessDefaults.helper.withLevel(HouseholdArea.homeCare, AccessLevel.none),
  );

  /// A real photo, four by three, so `Image.memory` decodes rather than
  /// failing the test on bytes that are no picture at all.
  static final Uint8List photoBytes = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 4, height: 3)),
  );
}
