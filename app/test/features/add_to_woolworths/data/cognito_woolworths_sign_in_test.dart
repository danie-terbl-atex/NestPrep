import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nestprep/features/add_to_woolworths/data/cognito_woolworths_sign_in.dart';
import 'package:nestprep/features/add_to_woolworths/data/emulator_woolworths_sign_in.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_sign_in.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

Matcher refusedAs(WoolworthsProblem problem) => throwsA(
  isA<WoolworthsFailure>().having((f) => f.problem, 'problem', problem),
);

void main() {
  const cognito = WoolworthsCognito(clientId: 'client1', region: 'eu-west-1');
  late List<http.Request> requests;
  late List<http.Response> replies;
  late CognitoWoolworthsSignIn signIn;

  http.Response reply(Object json, [int status = 200]) =>
      http.Response(jsonEncode(json), status);

  setUp(() {
    requests = [];
    replies = [];
    signIn = CognitoWoolworthsSignIn(
      client: MockClient((request) async {
        requests.add(request);
        return replies.removeAt(0);
      }),
    );
  });

  Map<String, Object?> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, Object?>;

  test('signs in with the password straight to Woolworths’ Cognito', () async {
    replies.add(
      reply({
        'AuthenticationResult': {
          'IdToken': 'id',
          'AccessToken': 'access',
          'RefreshToken': 'refresh-1',
        },
      }),
    );
    final step = await signIn.signIn(
      cognito: cognito,
      email: 'sam@example.com',
      password: 'secret',
    );
    expect(step, isA<WoolworthsSignedIn>());
    expect((step as WoolworthsSignedIn).refreshToken, 'refresh-1');
    final request = requests.single;
    expect(request.url, Uri.https('cognito-idp.eu-west-1.amazonaws.com', '/'));
    expect(
      request.headers['x-amz-target'],
      'AWSCognitoIdentityProviderService.InitiateAuth',
    );
    expect(
      request.headers['content-type'],
      startsWith('application/x-amz-json-1.1'),
    );
    expect(bodyOf(request), {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': 'client1',
      'AuthParameters': {'USERNAME': 'sam@example.com', 'PASSWORD': 'secret'},
    });
  });

  test('a code challenge is answered with the code and the session', () async {
    replies
      ..add(
        reply({
          'ChallengeName': 'SMS_MFA',
          'Session': 'session-1',
          'ChallengeParameters': {
            'CODE_DELIVERY_DESTINATION': '+27*****4567',
            'USER_ID_FOR_SRP': 'user-uuid',
          },
        }),
      )
      ..add(
        reply({
          'AuthenticationResult': {'RefreshToken': 'refresh-2'},
        }),
      );
    final asked = await signIn.signIn(
      cognito: cognito,
      email: 'sam@example.com',
      password: 'secret',
    ) as WoolworthsCodeAsked;
    expect(asked.sentTo, '+27*****4567');
    final step = await signIn.answer(asked, '123456');
    expect((step as WoolworthsSignedIn).refreshToken, 'refresh-2');
    expect(
      requests.last.headers['x-amz-target'],
      'AWSCognitoIdentityProviderService.RespondToAuthChallenge',
    );
    expect(bodyOf(requests.last), {
      'ChallengeName': 'SMS_MFA',
      'ClientId': 'client1',
      'Session': 'session-1',
      'ChallengeResponses': {'USERNAME': 'user-uuid', 'SMS_MFA_CODE': '123456'},
    });
  });

  test('an email code is answered as one', () async {
    replies
      ..add(reply({'ChallengeName': 'EMAIL_OTP', 'Session': 's'}))
      ..add(
        reply({
          'AuthenticationResult': {'RefreshToken': 'r'},
        }),
      );
    final asked = await signIn.signIn(
      cognito: cognito,
      email: 'a@b.co',
      password: 'p',
    ) as WoolworthsCodeAsked;
    await signIn.answer(asked, '654321');
    expect(bodyOf(requests.last)['ChallengeResponses'], {
      'USERNAME': 'a@b.co',
      'EMAIL_OTP_CODE': '654321',
    });
  });

  test('a challenge NestPrep cannot answer is said plainly', () async {
    replies.add(
      reply({'ChallengeName': 'NEW_PASSWORD_REQUIRED', 'Session': 's'}),
    );
    await expectLater(
      signIn.signIn(cognito: cognito, email: 'a@b.co', password: 'p'),
      refusedAs(WoolworthsProblem.cannotLinkHere),
    );
  });

  final refusals = {
    'NotAuthorizedException': WoolworthsProblem.wrongSignIn,
    'UserNotFoundException': WoolworthsProblem.wrongSignIn,
    'CodeMismatchException': WoolworthsProblem.wrongCode,
    'ExpiredCodeException': WoolworthsProblem.signInExpired,
    'TooManyRequestsException': WoolworthsProblem.tooManyTries,
    'LimitExceededException': WoolworthsProblem.tooManyTries,
    'PasswordResetRequiredException': WoolworthsProblem.cannotLinkHere,
    'UserNotConfirmedException': WoolworthsProblem.cannotLinkHere,
    'InternalErrorException': WoolworthsProblem.signInUnreachable,
  };
  for (final MapEntry(key: type, value: problem) in refusals.entries) {
    test('$type is ${problem.name}', () async {
      replies.add(reply({'__type': type, 'message': 'words'}, 400));
      await expectLater(
        signIn.signIn(cognito: cognito, email: 'a@b.co', password: 'p'),
        refusedAs(problem),
      );
    });
  }

  test('a session that ran out is an expired sign-in', () async {
    replies.add(
      reply({
        '__type': 'NotAuthorizedException',
        'message': 'Invalid session for the user, session is expired.',
      }, 400),
    );
    await expectLater(
      signIn.answer(
        const WoolworthsCodeAsked(
          cognito: cognito,
          challengeName: 'SMS_MFA',
          session: 's',
          username: 'u',
        ),
        '123456',
      ),
      refusedAs(WoolworthsProblem.signInExpired),
    );
  });

  test('Cognito down is unreachable', () async {
    replies.add(http.Response('<html>', 503));
    await expectLater(
      signIn.signIn(cognito: cognito, email: 'a@b.co', password: 'p'),
      refusedAs(WoolworthsProblem.signInUnreachable),
    );
  });

  group('the emulator’s stand-in', () {
    const standIn = EmulatorWoolworthsSignIn();

    test('signs anybody in, with the token the emulator accepts', () async {
      final step = await standIn.signIn(
        cognito: cognito,
        email: 'parent@oak.nest',
        password: 'anything',
      );
      expect(
        (step as WoolworthsSignedIn).refreshToken,
        'emulator-woolworths-refresh',
      );
    });

    test('an email with "code" in it asks for 123456 first', () async {
      final asked = await standIn.signIn(
        cognito: cognito,
        email: 'code@oak.nest',
        password: 'anything',
      ) as WoolworthsCodeAsked;
      await expectLater(
        standIn.answer(asked, '000000'),
        refusedAs(WoolworthsProblem.wrongCode),
      );
      expect(await standIn.answer(asked, '123456'), isA<WoolworthsSignedIn>());
    });
  });
}
