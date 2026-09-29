import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/links/external_link_opener.dart';
import '../../../shared/state/action_failure.dart';
import '../../family_profiles/data/family_profile_repository.dart';
import '../../family_profiles/model/member_health.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import '../data/nanny_hub_repository.dart';
import '../data/photo_picker.dart';
import '../data/shift_repository.dart';
import '../model/child_in_care.dart';
import '../model/nanny_access.dart';
import '../model/nanny_hub.dart';
import '../model/nanny_hub_view.dart';
import 'care_listeners.dart';
import 'hub_edits.dart';
import 'hub_listeners.dart';
import 'photo_library.dart';

/// The hub's controller, on the shell route above every hub screen so moving
/// between the sheet, the guide and a card does not reopen the listeners (the
/// family feature's shape, foundation ADR-0006).
///
/// It joins the hub's own records with the household's members and what
/// family profiles lets the viewer read, into one `NannyHubView`. Shift mode
/// has its own controller, because it follows one shift's log.
final class NannyHubController extends ChangeNotifier with ActionFailureHolder {
  NannyHubController({
    required NannyHubRepository nannyHubRepository,
    required ShiftRepository shiftRepository,
    required FamilyProfileRepository familyProfileRepository,
    required this.householdId,
    required HouseholdView household,
    required this.photos,
    required this._photoPicker,
    required this._linkOpener,
  }) : _shiftRepository = shiftRepository,
       _members = household.members,
       _access = NannyAccess.of(household) {
    _hubListeners = HubListeners(
      nannyHubRepository: nannyHubRepository,
      shiftRepository: shiftRepository,
      householdId: householdId,
      onChange: _onHub,
    );
    _care = CareListeners(
      familyProfileRepository: familyProfileRepository,
      householdId: householdId,
      onChange: _publish,
    );
    edit = HubEdits(
      nannyHubRepository: nannyHubRepository,
      photos: photos,
      householdId: householdId,
      memberId: _access.viewerMemberId ?? '',
      runAction: runAction,
    );
    _start();
  }

  final ShiftRepository _shiftRepository;
  final PhotoPicker _photoPicker;
  final ExternalLinkOpener _linkOpener;
  final String householdId;

  /// The hub's photos, shared by every screen under it.
  final PhotoLibrary photos;

  late final HubListeners _hubListeners;
  late final CareListeners _care;

  /// The changes a screen can make, one method per record. Kept apart so this
  /// file stays about reading (`ENG-05`).
  late final HubEdits edit;

  List<Member> _members;
  NannyAccess _access;
  AsyncState<NannyHub> _hub = const AsyncLoading();
  AsyncState<NannyHubView> _view = const AsyncLoading();

  AsyncState<NannyHubView> get view => _view;

  /// What the viewer may see and do — the rules' mirror (`FE-04`).
  NannyAccess get access => _access;

  /// A child's medication, or null when the viewer may not see it.
  AsyncState<MemberHealth>? healthOf(String memberId) =>
      _care.healthOf(memberId);

  /// Who family may start a shift for: every grown-up but the viewer — a
  /// carer without their phone, a grandparent babysitting.
  List<Member> get carersToStartFor => [
    for (final member in _members)
      if (member.role != MemberRole.kid && member.id != _access.viewerMemberId)
        member,
  ];

  Member? memberById(String memberId) =>
      _members.where((member) => member.id == memberId).firstOrNull;

  /// The household's members or the viewer's grant changed. A grant change
  /// moves which reads are allowed, so the reads start again.
  void followHousehold(HouseholdView household) {
    final access = NannyAccess.of(household);
    if (listEquals(_members, household.members) && access == _access) return;
    final grantMoved = access != _access;
    _members = household.members;
    _access = access;
    if (grantMoved) {
      unawaited(retry());
      return;
    }
    _publish();
  }

  Future<void> retry() async {
    await _hubListeners.stop();
    await _care.stop();
    _hub = const AsyncLoading();
    _view = const AsyncLoading();
    notifyListeners();
    _start();
  }

  /// Starts a shift for [carerMemberId] — the viewer's own when null — and
  /// answers its id, or null when the rules refused and the banner says why.
  Future<String?> startShift({String? carerMemberId}) async {
    final startedBy = _access.viewerMemberId;
    if (startedBy == null) return null;
    String? shiftId;
    await runAction(() async {
      shiftId = await _shiftRepository.startShift(
        householdId: householdId,
        carerMemberId: carerMemberId ?? startedBy,
        startedBy: startedBy,
      );
    });
    return shiftId;
  }

  /// A photo from the camera or the library, or null when the person backed
  /// out or it would not open — which the banner then says.
  Future<Uint8List?> pickPhoto(PhotoSource source) async {
    Uint8List? picked;
    await runAction(() async {
      picked = await _photoPicker.pick(source);
    });
    return picked;
  }

  /// Hands a `tel:` link to the phone's dialler — one tap to call. Says so
  /// when nothing on the phone would place it.
  Future<void> call(Uri link) => runAction(() async {
    if (!await _linkOpener.open(link)) {
      throw const NannyHubFailure(NannyHubProblem.cannotCall);
    }
  });

  void _start() {
    _hubListeners.start();
    _care.startFood(mayReadProfiles: _access.family.seesEveryProfile);
  }

  void _onHub(AsyncState<NannyHub> hub) {
    _hub = hub;
    if (hub case AsyncData(:final value)) {
      photos.ensure([
        for (final spot in value.guide) spot.photoId,
        for (final card in value.cardsById.values) card.photoId,
      ]);
    }
    _publish();
  }

  void _publish() {
    _view = switch (_hub) {
      AsyncLoading() => const AsyncLoading(),
      AsyncFailure(:final failure) => AsyncFailure(failure),
      AsyncData(:final value) => AsyncData(
        NannyHubView(
          hub: value,
          children: ChildInCare.gather(
            members: _members,
            cards: value.cardsById,
            family: _care.food,
            canSeeAllergiesOf: _access.canSeeAllergiesOf,
          ),
        ),
      ),
    };
    if (_view case AsyncData(:final value)) {
      unawaited(
        _care.followChildren([
          for (final child in value.children)
            if (_access.canSeeMedicationOf(child.memberId)) child.memberId,
        ]),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_hubListeners.stop());
    unawaited(_care.stop());
    super.dispose();
  }
}
