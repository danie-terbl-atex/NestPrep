import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/member.dart';
import '../data/two_homes_directory.dart';
import '../model/co_parent_home.dart';
import '../model/link_invite.dart';

/// Accepting the other home's code (household ADR-0004): check it, see
/// exactly what it offers, choose this home's profile for the child — or
/// make one — name and colour this home, and accept. The link then waits for
/// the other home to confirm.
final class JoinLinkController extends ChangeNotifier with ActionFailureHolder {
  JoinLinkController({
    required TwoHomesDirectory twoHomesDirectory,
    required this.householdId,
    required this.kids,
  }) : _directory = twoHomesDirectory;

  final TwoHomesDirectory _directory;
  final String householdId;

  /// This household's kid profiles, one of which may be the child.
  final List<Member> kids;

  LinkInvitePreview? _preview;
  bool _isBusy = false;

  /// The chosen kid profile's id, or null for "add as a new kid".
  String? _childId;
  String _homeName = '';
  MemberColor _color = MemberColor.sky;
  String? _linkId;

  LinkInvitePreview? get preview => _preview;
  bool get isBusy => _isBusy;
  String? get childId => _childId;
  bool get addsNewChild => _childId == null;
  String get homeName => _homeName;
  MemberColor get color => _color;

  /// Set once accepted: the link is waiting for the other home.
  String? get linkId => _linkId;

  bool get canAccept =>
      _preview != null && _homeName.trim().isNotEmpty && !_isBusy;

  Future<void> check(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || _isBusy) return;
    await _busy(() async {
      final preview = await _directory.previewInvite(trimmed);
      _preview = preview;
      // The profile whose name matches the child's is almost always theirs.
      _childId = kids
          .where(
            (kid) => kid.displayName.trim().toLowerCase().startsWith(
              preview.childName.toLowerCase(),
            ),
          )
          .firstOrNull
          ?.id;
      if (_color == preview.home.color) {
        _color = MemberColor.values.firstWhere((each) => each != _color);
      }
    });
  }

  /// Back to typing a code.
  void startOver() {
    _preview = null;
    dismissActionFailure();
    notifyListeners();
  }

  void chooseChild(String? memberId) {
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

  Future<void> accept() async {
    final preview = _preview;
    if (preview == null || !canAccept) return;
    await _busy(() async {
      _linkId = await _directory.acceptInvite(
        householdId: householdId,
        code: preview.code,
        home: CoParentHome(name: _homeName.trim(), color: _color),
        childMemberId: _childId,
        newChildName: _childId == null ? preview.childName : null,
      );
    });
  }

  Future<void> _busy(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    await runAction(action);
    _isBusy = false;
    notifyListeners();
  }
}
