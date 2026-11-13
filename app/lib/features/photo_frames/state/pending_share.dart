import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/app_log.dart';
import '../model/shared_page.dart';
import '../model/shared_pdf.dart';

final class PendingShare extends ChangeNotifier {
  PendingShare({required Stream<Uri> links}) {
    _subscription = links.listen(
      _offer,
      onError: (Object error) =>
          AppLog.failure('share link', code: 'stream', error: error),
    );
  }

  late final StreamSubscription<Uri> _subscription;
  SharedPage? _page;
  SharedPdf? _pdf;

  SharedPage? get page => _page;
  SharedPdf? get pdf => _pdf;
  bool get isWaiting => _page != null || _pdf != null;

  SharedPage? take() {
    final page = _page;
    if (page == null) return null;
    _page = null;
    notifyListeners();
    return page;
  }

  SharedPdf? takePdf() {
    final pdf = _pdf;
    if (pdf == null) return null;
    _pdf = null;
    notifyListeners();
    return pdf;
  }

  void _offer(Uri uri) {
    if (SharedPdf.fromLink(uri) case final pdf?) {
      _page = null;
      _pdf = pdf;
      return notifyListeners();
    }
    if (uri.queryParameters.containsKey('pdf')) return;
    final page = SharedPage.fromLink(uri);
    if (page == null) return;
    _pdf = null;
    _page = page;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
