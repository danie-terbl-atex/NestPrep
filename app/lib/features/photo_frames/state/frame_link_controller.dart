import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../household/model/member.dart';
import '../data/photo_frame_directory.dart';
import '../model/frame_code.dart';
import '../model/frame_panels.dart';

enum FrameLinkStep { code, details, linked }

final class FrameLinkController extends ChangeNotifier {
  FrameLinkController({
    required PhotoFrameDirectory photoFrameDirectory,
    required this.householdId,
    required this.helpers,
  }) : _directory = photoFrameDirectory;

  final PhotoFrameDirectory _directory;
  final String householdId;
  final List<Member> helpers;

  FrameLinkStep _step = FrameLinkStep.code;
  bool _isTyping = false;
  String _typedCode = '';
  String? _code;
  bool _scanWasNotOurs = false;
  FramePanels _panels = const FramePanels(addEvents: true, share: true);
  bool _isLinking = false;
  AppFailure? _failure;
  bool _isDisposed = false;

  FrameLinkStep get step => _step;
  bool get isTyping => _isTyping;
  String get typedCode => _typedCode;
  String? get code => _code;
  bool get scanWasNotOurs => _scanWasNotOurs;
  FramePanels get panels => _panels;
  bool get isLinking => _isLinking;
  AppFailure? get failure => _failure;
  bool get canUseTypedCode => FrameCode.isComplete(_typedCode);

  void typeInstead() {
    _isTyping = true;
    _scanWasNotOurs = false;
    notifyListeners();
  }

  void scanInstead() {
    _isTyping = false;
    notifyListeners();
  }

  void setTypedCode(String typed) {
    final next = FrameCode.normalise(typed);
    if (next == _typedCode) return;
    _typedCode = next;
    notifyListeners();
  }

  void useTypedCode() {
    if (!canUseTypedCode) return;
    _chooseCode(_typedCode);
  }

  void scanned(String raw) {
    if (_step != FrameLinkStep.code || _isTyping) return;
    final code = FrameCode.fromScan(raw);
    if (code == null) {
      if (_scanWasNotOurs) return;
      _scanWasNotOurs = true;
      notifyListeners();
      return;
    }
    _chooseCode(code);
  }

  void differentCode() {
    _step = FrameLinkStep.code;
    _code = null;
    _failure = null;
    _scanWasNotOurs = false;
    notifyListeners();
  }

  void setPanels(FramePanels panels) {
    _panels = panels;
    notifyListeners();
  }

  Future<void> link(String name) async {
    final code = _code;
    if (_isLinking || code == null) return;
    _isLinking = true;
    _failure = null;
    notifyListeners();
    try {
      await _directory.claimPairing(
        householdId: householdId,
        code: code,
        name: name.trim(),
        panels: _panels,
      );
      _step = FrameLinkStep.linked;
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _isLinking = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _chooseCode(String code) {
    _code = code;
    _scanWasNotOurs = false;
    _failure = null;
    _step = FrameLinkStep.details;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
