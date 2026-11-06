import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../model/woolworths_sign_in.dart';
import 'woolworths_account_sign_in.dart';

/// Woolworths' AWS Cognito, called from the phone: `USER_PASSWORD_AUTH`,
/// and an SMS or email code answered with `RespondToAuthChallenge`. Nothing
/// it sends or receives is logged — only Cognito's error type.
final class CognitoWoolworthsSignIn implements WoolworthsAccountSignIn {
  CognitoWoolworthsSignIn({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  static const _codeChallenges = {
    'SMS_MFA': 'SMS_MFA_CODE',
    'EMAIL_OTP': 'EMAIL_OTP_CODE',
  };

  final http.Client _client;
  final Duration timeout;

  @override
  Future<WoolworthsSignInStep> signIn({
    required WoolworthsCognito cognito,
    required String email,
    required String password,
  }) async => _step(
    cognito,
    email,
    await _send(cognito, 'InitiateAuth', {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': cognito.clientId,
      'AuthParameters': {'USERNAME': email, 'PASSWORD': password},
    }),
  );

  @override
  Future<WoolworthsSignInStep> answer(
    WoolworthsCodeAsked asked,
    String code,
  ) async => _step(
    asked.cognito,
    asked.username,
    await _send(asked.cognito, 'RespondToAuthChallenge', {
      'ChallengeName': asked.challengeName,
      'ClientId': asked.cognito.clientId,
      'Session': asked.session,
      'ChallengeResponses': {
        'USERNAME': asked.username,
        _codeChallenges[asked.challengeName]!: code,
      },
    }),
  );

  WoolworthsSignInStep _step(
    WoolworthsCognito cognito,
    String username,
    Object? json,
  ) {
    if (json case {'AuthenticationResult': {'RefreshToken': final String token}}
        when token.isNotEmpty) {
      return WoolworthsSignedIn(token);
    }
    if (json
        case {
          'ChallengeName': final String name,
          'Session': final String session,
        }
        when _codeChallenges.containsKey(name)) {
      final parameters = switch (json['ChallengeParameters']) {
        final Map<Object?, Object?> parameters => parameters,
        _ => const <Object?, Object?>{},
      };
      return WoolworthsCodeAsked(
        cognito: cognito,
        challengeName: name,
        session: session,
        username: switch (parameters['USER_ID_FOR_SRP']) {
          final String id when id.isNotEmpty => id,
          _ => username,
        },
        sentTo: switch (parameters['CODE_DELIVERY_DESTINATION']) {
          final String where when where.isNotEmpty => where,
          _ => null,
        },
      );
    }
    if (json case {'ChallengeName': String()}) {
      AppLog.failure('woolworths sign-in', code: 'unanswerable-challenge');
      throw const WoolworthsFailure(WoolworthsProblem.cannotLinkHere);
    }
    AppLog.failure('woolworths sign-in', code: 'unexpected-shape');
    throw const WoolworthsFailure(WoolworthsProblem.signInUnreachable);
  }

  Future<Object?> _send(
    WoolworthsCognito cognito,
    String action,
    Map<String, Object?> body,
  ) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            cognito.endpoint,
            headers: {
              'content-type': 'application/x-amz-json-1.1',
              'x-amz-target': 'AWSCognitoIdentityProviderService.$action',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw _unreachable('timeout');
    } on http.ClientException {
      throw _unreachable('client');
    }
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw _unreachable('not-json-${response.statusCode}');
    }
    final status = response.statusCode;
    if (status >= 200 && status < 300) return json;
    if (status >= 500) throw _unreachable('$status');
    throw refusal(json);
  }

  /// What a Cognito refusal means for the member, by its `__type`.
  static WoolworthsFailure refusal(Object? json) {
    final type = switch (json) {
      {'__type': final String type} => type.split('#').last,
      _ => 'unknown',
    };
    AppLog.failure('woolworths sign-in', code: type);
    final message = switch (json) {
      {'message': final String message} => message.toLowerCase(),
      _ => '',
    };
    return WoolworthsFailure(switch (type) {
      'NotAuthorizedException' when message.contains('session') =>
        WoolworthsProblem.signInExpired,
      'NotAuthorizedException' ||
      'UserNotFoundException' => WoolworthsProblem.wrongSignIn,
      'CodeMismatchException' => WoolworthsProblem.wrongCode,
      'ExpiredCodeException' => WoolworthsProblem.signInExpired,
      'TooManyRequestsException' ||
      'TooManyFailedAttemptsException' ||
      'LimitExceededException' => WoolworthsProblem.tooManyTries,
      'PasswordResetRequiredException' ||
      'UserNotConfirmedException' => WoolworthsProblem.cannotLinkHere,
      _ => WoolworthsProblem.signInUnreachable,
    });
  }

  WoolworthsFailure _unreachable(String code) {
    AppLog.failure('woolworths sign-in', code: code);
    return const WoolworthsFailure(WoolworthsProblem.signInUnreachable);
  }
}
