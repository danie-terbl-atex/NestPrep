import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../household/model/member.dart';
import '../data/photo_frame_directory.dart';
import '../data/photo_frame_repository.dart';
import '../model/frame_code.dart';
import '../model/frame_groceries.dart';
import '../model/frame_panels.dart';

enum FrameLinkStep { code, details, linked }

final class FrameLinkController extends ChangeNotifier {
  FrameLinkController({
    required PhotoFrameDirectory photoFrameDirectory,
    required PhotoFrameRepository photoFrameRepository,
    required this._woolworthsStoreFor,
    required this.householdId,
    required this.helpers,
  }) : _directory = photoFrameDirectory,
       _repository = photoFrameRepository;

  final PhotoFrameDirectory _directory;
  final PhotoFrameRepository _repository;
  final WoolworthsStoreLookup _woolworthsStoreFor;
  final String householdId;
  final List<Member> helpers;

  FrameLinkStep _step = FrameLinkStep.code;
  bool _isTyping = false;
  String _typedCode = '';
  String? _code;
  bool _scanWasNotOurs = false;
  FramePanels _panels = const FramePanels(addEvents: true, share: true);
  FrameGroceries? _groceries;
  bool _isLinking = false;
  AppFailure? _failure;
  bool _groceriesDidNotSave = false;
  bool _isDisposed = false;

  FrameLinkStep get step => _step;
  bool get isTyping => _isTyping;
  String get typedCode => _typedCode;
  String? get code => _code;
  bool get scanWasNotOurs => _scanWasNotOurs;
  FramePanels get panels => _panels;
  FrameGroceries? get groceries => _groceries;
  bool get isLinking => _isLinking;
  AppFailure? get failure => _failure;
  bool get groceriesDidNotSave => _groceriesDidNotSave;
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

  void setGroceries(FrameGroceries? groceries) {
    _groceries = groceries;
    notifyListeners();
  }

  Future<void> link(String name) async {
    final code = _code;
    if (_isLinking || code == null) return;
    _isLinking = true;
    _failure = null;
    notifyListeners();
    try {
      final groceries = await _groceries?.located(_woolworthsStoreFor);
      final frameId = await _directory.claimPairing(
        householdId: householdId,
        code: code,
        name: name.trim(),
        panels: _panels,
      );
      _step = FrameLinkStep.linked;
      if (groceries != null) await _saveGroceries(frameId, groceries);
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _isLinking = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// The pairing callable carries no groceries, so they follow in a second
  /// write. The frame is linked whatever that write says.
  Future<void> _saveGroceries(String frameId, FrameGroceries groceries) async {
    try {
      await _repository.setGroceries(
        householdId: householdId,
        frameId: frameId,
        groceries: groceries,
      );
    } on AppFailure {
      _groceriesDidNotSave = true;
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
