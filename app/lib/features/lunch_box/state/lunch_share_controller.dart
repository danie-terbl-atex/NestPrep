import 'package:flutter/foundation.dart';

import '../../../shared/copy/app_copy.dart';
import '../../../shared/state/action_failure.dart';
import '../data/lunch_card_renderer.dart';
import '../data/lunch_card_sharer.dart';
import '../data/lunch_planner_composer.dart';
import '../model/lunch_board.dart';
import '../model/lunch_card_content.dart';
import '../model/lunch_card_format.dart';
import '../model/lunch_card_naming.dart';
import '../model/lunch_card_options.dart';
import '../model/lunch_card_style.dart';

/// Which planner the share screen prints or sends.
enum LunchPlannerKind {
  /// The week's plan written in, a page per child.
  filled,

  /// Every cell left to write in — the free printable.
  blank,
}

/// What the share screen is doing right now; one thing at a time.
enum LunchShareTask { sharingCard, printingPlanner, sendingPlanner }

/// The share screen's controller (lunch-box ADR-0005): the parent's choices
/// for this share, and the three ways a week leaves the phone — the card
/// image, the planner printed, the planner sent.
///
/// It is made each time the screen opens and holds nothing anywhere else,
/// which is what makes a first name opt-in *each time*. The week itself is
/// the lunch board's; this reads it and never copies it (`FE-07`).
final class LunchShareController extends ChangeNotifier
    with ActionFailureHolder {
  LunchShareController({
    required LunchCardRenderer cardRenderer,
    required LunchCardSharer cardSharer,
    required LunchPlannerComposer plannerComposer,
    required String? initialChildId,
    this.appLink,
  }) : _renderer = cardRenderer,
       _sharer = cardSharer,
       _planner = plannerComposer,
       _options = LunchCardOptions(childId: initialChildId);

  final LunchCardRenderer _renderer;
  final LunchCardSharer _sharer;
  final LunchPlannerComposer _planner;

  /// Where somebody gets the app — the household's invite link, when one is
  /// configured.
  final Uri? appLink;

  LunchCardOptions _options;
  LunchPlannerKind _plannerKind = LunchPlannerKind.filled;
  LunchShareTask? _task;
  (LunchBoard, LunchCardOptions, LunchCardContent)? _cached;

  LunchCardOptions get options => _options;
  LunchPlannerKind get plannerKind => _plannerKind;
  LunchShareTask? get task => _task;
  bool get isBusy => _task != null;

  /// The invite line's host, or null to name the app instead.
  String? get inviteHost {
    final host = appLink?.host;
    return host == null || host.isEmpty ? null : host;
  }

  /// The card for [board] with the choices as they are — worked out once
  /// per board and choice, not on every build (`FE-12`).
  LunchCardContent contentFor(LunchBoard board) {
    final cached = _cached;
    if (cached != null &&
        identical(cached.$1, board) &&
        cached.$2 == _options) {
      return cached.$3;
    }
    final content = LunchCardContent.from(board, _options);
    _cached = (board, _options, content);
    return content;
  }

  /// One child's week, or null for everyone's.
  void chooseChild(String? childId) =>
      _choose(_options.copyWith(childId: () => childId));

  void chooseFormat(LunchCardFormat format) =>
      _choose(_options.copyWith(format: format));

  void chooseStyle(LunchCardStyle style) =>
      _choose(_options.copyWith(style: style));

  void chooseNaming(LunchCardNaming naming) =>
      _choose(_options.copyWith(naming: naming));

  void setShowsInvite({required bool showsInvite}) =>
      _choose(_options.copyWith(showsInvite: showsInvite));

  void choosePlanner(LunchPlannerKind kind) {
    if (kind == _plannerKind) return;
    _plannerKind = kind;
    notifyListeners();
  }

  /// Draws the card and opens the share sheet with it. Nothing happens for a
  /// week with nothing packed — the screen does not offer it.
  Future<void> shareCard(LunchBoard board) async {
    final content = contentFor(board);
    if (content.isEmpty) return;
    final options = _options;
    await _run(LunchShareTask.sharingCard, () async {
      final png = await _renderer.render(
        content: content,
        options: options,
        inviteHost: inviteHost,
      );
      await _sharer.shareFile(
        LunchSharedFile(
          bytes: png,
          fileName: LunchShareCopy.cardFileName(board.week.key, options.format),
          mimeType: LunchSharedFile.png,
          subject: LunchShareCopy.shareSubject,
          text: LunchShareCopy.shareText(_linkToShare),
        ),
      );
    });
  }

  /// Opens the print dialog with the chosen planner.
  Future<void> printPlanner(LunchBoard board) =>
      _run(LunchShareTask.printingPlanner, () async {
        final pdf = await _composePlanner(board);
        await _sharer.printPdf(pdf: pdf, name: _plannerFileName(board));
      });

  /// Opens the share sheet with the chosen planner as a PDF.
  Future<void> sendPlanner(LunchBoard board) =>
      _run(LunchShareTask.sendingPlanner, () async {
        final pdf = await _composePlanner(board);
        await _sharer.shareFile(
          LunchSharedFile(
            bytes: pdf,
            fileName: _plannerFileName(board),
            mimeType: LunchSharedFile.pdf,
            subject: LunchShareCopy.plannerTitle,
            text: LunchShareCopy.plannerShareText,
          ),
        );
      });

  String? get _linkToShare => _options.showsInvite ? appLink?.toString() : null;

  bool get _isBlank => _plannerKind == LunchPlannerKind.blank;

  String _plannerFileName(LunchBoard board) =>
      LunchShareCopy.plannerFileName(_isBlank ? null : board.week.key);

  /// The planner has a page per child — every child, not only the four a
  /// card has room for — named the way the card would name them.
  Future<Uint8List> _composePlanner(LunchBoard board) => _planner.compose(
    content: _isBlank
        ? null
        : LunchCardContent.from(board, _options, limit: board.children.length),
    showsInvite: _options.showsInvite,
    inviteHost: inviteHost,
  );

  void _choose(LunchCardOptions options) {
    if (options == _options) return;
    _options = options;
    notifyListeners();
  }

  Future<void> _run(LunchShareTask task, Future<void> Function() work) async {
    if (_task != null) return;
    _task = task;
    notifyListeners();
    try {
      await runAction(work);
    } finally {
      _task = null;
      notifyListeners();
    }
  }
}
