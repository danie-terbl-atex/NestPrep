import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/member.dart';
import '../data/live_location_repository.dart';
import '../data/location_reporter.dart';
import '../model/live_location_view.dart';
import '../model/member_location.dart';
import '../model/share_duration.dart';

/// The live-location screen's controller (foundation ADR-0006).
///
/// It holds two things a household-scoped controller usually does not. **A
/// ticker**, because the only thing on this screen that changes while nobody
/// touches it is how old a position is — a pin that stopped arriving twenty
/// minutes ago while the label still says two is the failure this feature most
/// has to avoid (live-location ADR-0002). And **the reporter's problems**,
/// because a share that stopped on its own has to say so; silence looks like
/// standing still.
final class LiveLocationController extends ChangeNotifier
    with ActionFailureHolder {
  LiveLocationController({
    required LiveLocationRepository liveLocationRepository,
    required LocationReporter locationReporter,
    required this.householdId,
    required this.viewerMemberId,
    required this.members,
    DateTime Function()? now,
  }) : _repository = liveLocationRepository,
       _reporter = locationReporter,
       _now = now ?? DateTime.now {
    _subscribe();
  }

  /// How often the ages on screen are recounted. Far finer than the 90 seconds
  /// between two reports, so "last seen 3 minutes ago" is never more than half
  /// a minute behind itself.
  static const recount = Duration(seconds: 30);

  final LiveLocationRepository _repository;
  final LocationReporter _reporter;
  final DateTime Function() _now;
  final String householdId;

  /// The household's profiles, as the shell read them when this screen opened.
  /// Everybody is on this screen whether or not they are sharing, so the list
  /// is the household's and not the sharers'.
  final List<Member> members;

  /// The profile the signed-in account claimed here. It is the only one this
  /// screen can ever start a share for, and the rules agree (live-location
  /// ADR-0002).
  final String viewerMemberId;

  StreamSubscription<List<MemberLocation>>? _subscription;
  StreamSubscription<AppFailure>? _problems;
  Timer? _ticker;
  List<MemberLocation> _locations = const [];
  bool _hasResumed = false;

  AsyncState<LiveLocationView> _view = const AsyncLoading();

  AsyncState<LiveLocationView> get view => _view;

  Future<void> retry() async {
    await _cancel();
    _hasResumed = false;
    _locations = const [];
    _view = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  /// Starts sharing this member's own position, and nobody else's.
  Future<void> shareFor(ShareDuration duration) => runAction(
    () => _reporter.start(
      householdId: householdId,
      memberId: viewerMemberId,
      until: duration.endingFrom(_now()),
    ),
  );

  Future<void> stopSharing() => runAction(
    () => _reporter.stop(householdId: householdId, memberId: viewerMemberId),
  );

  void _subscribe() {
    _subscription = _repository.watchLocations(householdId).listen((locations) {
      _locations = locations;
      _publish();
      _resumeOwnShareIfOpen();
    }, onError: _onError);
    _problems = _reporter.problems.listen(recordFailure, onError: _onError);
    _ticker = Timer.periodic(recount, (_) => _publish());
  }

  /// A window the person opened before the app was last closed is still theirs
  /// until it ends, so reopening the screen picks it back up rather than
  /// leaving their pin to go stale under a label that says they are sharing.
  /// It never *starts* a share, only resumes one they are already inside.
  void _resumeOwnShareIfOpen() {
    if (_hasResumed) return;
    final own = _locations
        .where((location) => location.id == viewerMemberId)
        .firstOrNull;
    if (own == null || !own.isSharingAt(_now())) return;
    _hasResumed = true;
    unawaited(_resumeReporting(own.sharingUntil));
  }

  Future<void> _resumeReporting(DateTime until) => runAction(
    () => _reporter.start(
      householdId: householdId,
      memberId: viewerMemberId,
      until: until,
    ),
  );

  void _publish() {
    _view = AsyncData(
      LiveLocationView.from(
        members: members,
        locations: _locations,
        viewerMemberId: viewerMemberId,
        now: _now(),
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _view = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    _ticker = null;
    await _subscription?.cancel();
    await _problems?.cancel();
    _subscription = null;
    _problems = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
