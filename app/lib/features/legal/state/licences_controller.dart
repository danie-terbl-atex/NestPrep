import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../model/package_licences.dart';

/// The open-source licences this build carries, read once from Flutter's
/// registry — which is also where the bundled fonts' licences are added
/// (`registerFontLicences`).
final class LicencesController extends ChangeNotifier {
  LicencesController({Stream<LicenseEntry> Function()? licences})
    : _licences = licences ?? (() => LicenseRegistry.licenses) {
    _load();
  }

  final Stream<LicenseEntry> Function() _licences;

  AsyncState<List<PackageLicences>> _packages = const AsyncLoading();
  bool _isDisposed = false;

  AsyncState<List<PackageLicences>> get packages => _packages;

  /// One package's licences, or null while they are loading, failed, or the
  /// package is not in this build.
  PackageLicences? packageNamed(String name) => switch (_packages) {
    AsyncData(:final value) =>
      value.where((package) => package.package == name).firstOrNull,
    _ => null,
  };

  Future<void> retry() {
    _packages = const AsyncLoading();
    notifyListeners();
    return _load();
  }

  Future<void> _load() async {
    try {
      _packages = AsyncData(groupLicences(await _licences().toList()));
    } on Object catch (error) {
      AppLog.failure('licences', code: 'unreadable', error: error);
      _packages = AsyncFailure(UnknownFailure(error));
    }
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
