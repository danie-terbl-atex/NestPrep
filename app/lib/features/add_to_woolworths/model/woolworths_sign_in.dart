import 'package:flutter/foundation.dart';

/// Where the phone signs in to Woolworths: the Cognito app client and its
/// region, as `woolworthsStartLink` names them. Read from the Functions'
/// config on every link, never built into the app (add-to-woolworths
/// ADR-0001).
@immutable
final class WoolworthsCognito {
  const WoolworthsCognito({required this.clientId, required this.region});

  static final _clientId = RegExp(r'^[A-Za-z0-9]{1,128}$');
  static final _region = RegExp(r'^[a-z]{2}(-[a-z]+)+-[0-9]$');

  /// [clientId] and [region], or null when either could put the sign-in
  /// anywhere but an AWS Cognito endpoint.
  static WoolworthsCognito? tryFrom({
    required String clientId,
    required String region,
  }) => _clientId.hasMatch(clientId) && _region.hasMatch(region)
      ? WoolworthsCognito(clientId: clientId, region: region)
      : null;

  final String clientId;
  final String region;

  Uri get endpoint => Uri.https('cognito-idp.$region.amazonaws.com', '/');
}

/// Where a sign-in to Woolworths has got to.
sealed class WoolworthsSignInStep {
  const WoolworthsSignInStep();
}

/// Signed in: the refresh token to hand to `woolworthsCompleteLink`, and
/// then forget.
final class WoolworthsSignedIn extends WoolworthsSignInStep {
  const WoolworthsSignedIn(this.refreshToken);

  final String refreshToken;
}

/// Woolworths sent a code by SMS or email and wants it back.
final class WoolworthsCodeAsked extends WoolworthsSignInStep {
  const WoolworthsCodeAsked({
    required this.cognito,
    required this.challengeName,
    required this.session,
    required this.username,
    this.sentTo,
  });

  final WoolworthsCognito cognito;

  /// `SMS_MFA` or `EMAIL_OTP`.
  final String challengeName;

  /// Cognito's handle on this sign-in, sent back with the code.
  final String session;
  final String username;

  /// Where the code went, as Woolworths masks it — when it says.
  final String? sentTo;
}
