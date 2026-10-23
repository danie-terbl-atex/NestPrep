import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../shared/log/app_log.dart';
import '../model/pnp_sign_in_navigation.dart';
import '../model/pnp_sign_in_result.dart';
import 'pnp_sign_in_frame.dart';

/// Builds the page a member signs in to Pick n Pay on — the seam the link
/// screen takes, so a test never starts a real web view.
typedef PnpSignInPageBuilder = Widget Function({
  required Uri page,
  required ValueChanged<PnpSignInResult> onResult,
});

/// Pick n Pay's own sign-in page, inside the app (add-to-pnp ADR-0003 §3,
/// ADR-0005) — the one place `webview_flutter` is used. The member types
/// their password into PnP's page, never into NestPrep. Only
/// `login.pnp.co.za` may load; the redirect to `www.pnp.co.za/oidc_login`
/// is never loaded: its code and state are taken from the URL and handed to
/// [onResult] (`PnpSignInNavigation` decides). No JavaScript channel, no
/// page reads. Cookies are cleared before the page opens, so nobody else's
/// session is reused, and again when it closes, so no Pick n Pay session
/// stays in the app. The page opens exactly as the server built it: PnP's
/// sign-in server sends the member back to its form, round and round, when
/// `prompt=login` is added (seen on a device 2026-10-13; ADR-0006).
class PnpLoginWebView extends StatefulWidget {
  const PnpLoginWebView({
    required this.page,
    required this.onResult,
    super.key,
  });

  /// Builds one, for the link screen's [PnpSignInPageBuilder].
  static Widget build({
    required Uri page,
    required ValueChanged<PnpSignInResult> onResult,
  }) => PnpLoginWebView(page: page, onResult: onResult);

  final Uri page;
  final ValueChanged<PnpSignInResult> onResult;

  @override
  State<PnpLoginWebView> createState() => _PnpLoginWebViewState();
}

class _PnpLoginWebViewState extends State<PnpLoginWebView> {
  late final WebViewController _controller;
  var _phase = PnpSignInPhase.loading;
  var _isRefusedNoticeShown = false;
  var _isDone = false;
  Uri? _showing;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _decide,
          onPageStarted: (url) => _showing = Uri.tryParse(url),
          onPageFinished: (_) => _setPhase(PnpSignInPhase.ready),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) _setPhase(PnpSignInPhase.failed);
          },
          onHttpError: (error) {
            if (PnpSignInNavigation.isThePage(error.request?.uri, _showing)) {
              _setPhase(PnpSignInPhase.failed);
            }
          },
        ),
      );
    unawaited(_open());
  }

  /// A clean jar first, then the page: awaited in that order, so the page
  /// never sees a cookie from an earlier sign-in.
  Future<void> _open() async {
    _setPhase(PnpSignInPhase.loading);
    try {
      await WebViewCookieManager().clearCookies();
      await _controller.loadRequest(widget.page);
    } on Exception catch (error) {
      // The platform could not start the page: the frame says so, with a
      // retry (`FE-09`); the detail is for the log.
      AppLog.failure('pnp sign-in page', code: 'load', error: error);
      _setPhase(PnpSignInPhase.failed);
    }
  }

  NavigationDecision _decide(NavigationRequest request) {
    switch (PnpSignInNavigation.decide(Uri.tryParse(request.url))) {
      case PnpNavigationAllowed():
        return NavigationDecision.navigate;
      case PnpNavigationRedirect(:final result):
        if (!_isDone) {
          _isDone = true;
          widget.onResult(result);
        }
        return NavigationDecision.prevent;
      case PnpNavigationRefused():
        if (mounted) setState(() => _isRefusedNoticeShown = true);
        return NavigationDecision.prevent;
    }
  }

  void _setPhase(PnpSignInPhase phase) {
    if (!mounted || _phase == phase) return;
    // A page that failed stays failed until the member retries.
    if (_phase == PnpSignInPhase.failed && phase == PnpSignInPhase.ready) {
      return;
    }
    setState(() => _phase = phase);
  }

  void _retry() {
    setState(() => _phase = PnpSignInPhase.loading);
    unawaited(_open());
  }

  @override
  void dispose() {
    unawaited(WebViewCookieManager().clearCookies());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PnpSignInFrame(
    phase: _phase,
    isRefusedNoticeShown: _isRefusedNoticeShown,
    onRetry: _retry,
    onDismissNotice: () => setState(() => _isRefusedNoticeShown = false),
    page: WebViewWidget(controller: _controller),
  );
}
