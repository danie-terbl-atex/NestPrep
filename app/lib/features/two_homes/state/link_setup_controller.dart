import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/data/invite_sharer.dart';
import '../../household/model/member.dart';
import '../data/two_homes_directory.dart';
import '../model/co_parent_home.dart';
import '../model/link_invite.dart';
import 'schedule_draft.dart';

/// Making a code for the other home (household ADR-0004): which child, what
/// this home is called and its colour, and the schedule it proposes. The
/// code leaves through the platform share sheet, like a household invite
/// (household ADR-0003).
final class LinkSetupController extends ChangeNotifier
    with ActionFailureHolder {
  LinkSetupController({
    required TwoHomesDirectory twoHomesDirectory,
    required InviteSharer inviteSharer,
    required this.householdId,
    required this.kids,
    required this.draft,
  }) : _directory = twoHomesDirectory,
       _sharer = inviteSharer,
       _childId = kids.length == 1 ? kids.single.id : null {
    draft.addListener(notifyListeners);
  }

  final TwoHomesDirectory _directory;
  final InviteSharer _sharer;
  final String householdId;

  /// The household's kid profiles, the only ones a link can be for.
  final List<Member> kids;

  /// The schedule being chosen. This controller owns it and disposes it.
  final ScheduleDraft draft;

  String? _childId;
  String _homeName = '';
  MemberColor _color = MemberColor.coral;
  bool _isCreating = false;
  LinkInviteCode? _invite;
  InviteShareOutcome? _shareOutcome;

  String? get childId => _childId;
  String get homeName => _homeName;
  MemberColor get color => _color;
  bool get isCreating => _isCreating;
  LinkInviteCode? get invite => _invite;
  InviteShareOutcome? get shareOutcome => _shareOutcome;

  Member? get child => kids.where((kid) => kid.id == _childId).firstOrNull;

  bool get canCreate =>
      child != null &&
      _homeName.trim().isNotEmpty &&
      draft.schedule.isComplete &&
      !_isCreating;

  void chooseChild(String memberId) {
    if (memberId == _childId) return;
    _childId = memberId;
    notifyListeners();
  }

  void nameHome(String name) {
    if (name == _homeName) return;
    _homeName = name;
    notifyListeners();
  }

  void chooseColor(MemberColor color) {
    if (color == _color) return;
    _color = color;
    notifyListeners();
  }

  /// Makes the code, and shares it at once — the share sheet is where a code
  /// is going anyway.
  Future<void> create() async {
    final childId = _childId;
    if (!canCreate || childId == null) return;
    _isCreating = true;
    notifyListeners();
    await runAction(() async {
      _invite = await _directory.createInvite(
        householdId: householdId,
        childMemberId: childId,
        home: CoParentHome(name: _homeName.trim(), color: _color),
        schedule: draft.schedule,
      );
    });
    _isCreating = false;
    notifyListeners();
    if (_invite != null) await share();
  }

  Future<void> share() async {
    final invite = _invite;
    final child = this.child;
    if (invite == null || child == null) return;
    final name = child.displayName.trim().split(RegExp(r'\s+')).first;
    _shareOutcome = await _sharer.share(
      subject: TwoHomesSetupCopy.shareSubject(name),
      text: TwoHomesSetupCopy.shareMessage(
        child: name,
        code: invite.code,
        appLink: _sharer.appLink,
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    draft
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
