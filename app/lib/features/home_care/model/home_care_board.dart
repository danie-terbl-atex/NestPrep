import '../../household/model/member.dart';
import 'cleaning_job.dart';
import 'home_care_product.dart';
import 'home_care_room.dart';
import 'job_status.dart';

/// The three piles a job list is sorted into.
enum JobPile {
  /// With the helper: assigned, started, or sent back.
  toDo,

  /// Handed in, waiting for a parent.
  toReview,

  /// Approved.
  done;

  bool holds(JobStatus status) => switch (this) {
    JobPile.toDo => status.isWithHelper,
    JobPile.toReview => status.isWaitingForReview,
    JobPile.done => status.isDone,
  };
}

/// Home care's three live reads and the household's members, as one value a
/// screen renders — so a job is never shown without the room and products it
/// names (foundation ADR-0006).
final class HomeCareBoard {
  HomeCareBoard({
    required this.jobs,
    required this.rooms,
    required this.products,
    required this.members,
  });

  final List<CleaningJob> jobs;
  final List<HomeCareRoom> rooms;
  final List<HomeCareProduct> products;
  final List<Member> members;

  late final Map<String, HomeCareRoom> _roomsById = {
    for (final room in rooms) room.id: room,
  };
  late final Map<String, HomeCareProduct> _productsById = {
    for (final product in products) product.id: product,
  };

  /// A pile's jobs in the order they matter: what is due soonest first while
  /// there is work to do, the most recent first once it is done.
  List<CleaningJob> jobsIn(JobPile pile) {
    final held = jobs.where((job) => pile.holds(job.status)).toList();
    held.sort(
      (a, b) => pile == JobPile.done
          ? b.dueDate.compareTo(a.dueDate)
          : a.dueDate.compareTo(b.dueDate),
    );
    return held;
  }

  int countIn(JobPile pile) =>
      jobs.where((job) => pile.holds(job.status)).length;

  CleaningJob? jobById(String jobId) =>
      jobs.where((job) => job.id == jobId).firstOrNull;

  HomeCareRoom? roomById(String roomId) => _roomsById[roomId];

  /// A job's products, in the order the parent chose them; one that has since
  /// been deleted from the library is left out.
  List<HomeCareProduct> productsOf(CleaningJob job) => [
    for (final id in job.productIds) ?_productsById[id],
  ];

  Member? memberById(String memberId) =>
      members.where((member) => member.id == memberId).firstOrNull;

  /// How many jobs are still open in a room, for the rooms list.
  int openJobsIn(String roomId) =>
      jobs.where((job) => job.roomId == roomId && !job.status.isDone).length;

  List<HomeCareRoom> get roomsByName =>
      [...rooms]..sort((a, b) => a.name.compareTo(b.name));

  List<HomeCareProduct> get productsByName =>
      [...products]..sort((a, b) => a.name.compareTo(b.name));
}
