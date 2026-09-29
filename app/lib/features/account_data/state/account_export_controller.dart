import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/account_data_gateway.dart';
import '../data/export_sharer.dart';
import '../model/account_export.dart';

/// The Download my data screen's controller (accounts ADR-0006): ask the
/// server for an export, fetch it while its hour lasts, and hand it to the
/// share sheet as often as the person likes.
///
/// [export] is `AsyncData(null)` before anything is asked — the idle screen
/// — loading while the server gathers it, and the downloaded export once it
/// is on the phone.
final class AccountExportController extends ChangeNotifier {
  AccountExportController({
    required AccountDataGateway accountDataGateway,
    required ExportSharer exportSharer,
  }) : _gateway = accountDataGateway,
       _sharer = exportSharer;

  final AccountDataGateway _gateway;
  final ExportSharer _sharer;

  AsyncState<DownloadedExport?> _export = const AsyncData(null);
  bool _isSharing = false;
  AppFailure? _shareFailure;
  bool _isDisposed = false;

  AsyncState<DownloadedExport?> get export => _export;
  bool get isPreparing => _export is AsyncLoading<DownloadedExport?>;
  bool get isSharing => _isSharing;
  AppFailure? get shareFailure => _shareFailure;

  Future<void> prepare() async {
    if (isPreparing) return;
    _export = const AsyncLoading();
    _shareFailure = null;
    _notify();
    try {
      final written = await _gateway.exportData();
      final bytes = await _gateway.download(written);
      _export = AsyncData(DownloadedExport(export: written, bytes: bytes));
    } on AppFailure catch (failure) {
      _export = AsyncFailure(failure);
    }
    _notify();
  }

  Future<void> share() async {
    final ready = switch (_export) {
      AsyncData(:final value?) => value,
      _ => null,
    };
    if (ready == null || _isSharing) return;
    _isSharing = true;
    _shareFailure = null;
    _notify();
    final opened = await _sharer.share(
      fileName: ready.export.fileName,
      bytes: ready.bytes,
    );
    _isSharing = false;
    _shareFailure = opened
        ? null
        : const AccountDataFailure(AccountDataProblem.shareUnavailable);
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
