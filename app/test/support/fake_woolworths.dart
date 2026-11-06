import 'dart:async';

import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_woolworths/data/woolworths_account_sign_in.dart';
import 'package:nestprep/features/add_to_woolworths/data/woolworths_directory.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_link_status.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_sign_in.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

/// The Woolworths callables, answered by the test. A link completes with any
/// refresh token unless [completeFailure] says otherwise; pushes are
/// recorded with their packs.
final class FakeWoolworthsDirectory implements WoolworthsDirectory {
  WoolworthsLinkStatus status = const WoolworthsLinkStatus.unlinked();
  AppFailure? statusFailure;
  AppFailure? startFailure;
  AppFailure? completeFailure;
  CartPushResult? pushResult;
  final pushFailures = <AppFailure>[];
  Completer<void>? pushGate;

  static const cognito = WoolworthsCognito(
    clientId: 'testclient',
    region: 'eu-west-1',
  );

  var starts = 0;
  var unlinks = 0;
  final completions = <String>[];
  final pushes =
      <
        ({
          String householdId,
          List<String> itemIds,
          Map<String, int> quantities,
        })
      >[];

  @override
  Future<WoolworthsLinkStatus> linkStatus() async {
    if (statusFailure case final failure?) throw failure;
    return status;
  }

  @override
  Future<WoolworthsCognito> startLink() async {
    starts++;
    if (startFailure case final failure?) throw failure;
    return cognito;
  }

  @override
  Future<WoolworthsLinkStatus> completeLink({
    required String refreshToken,
  }) async {
    completions.add(refreshToken);
    if (completeFailure case final failure?) throw failure;
    return status = WoolworthsLinkStatus(
      isLinked: true,
      linkedAt: DateTime.utc(2026, 11, 5, 9),
      emailMasked: 'p***@o***.nest',
    );
  }

  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  }) async {
    pushes.add((
      householdId: householdId,
      itemIds: itemIds,
      quantities: quantities,
    ));
    await pushGate?.future;
    if (pushFailures.isNotEmpty) throw pushFailures.removeAt(0);
    return pushResult ??
        const CartPushResult(
          added: [],
          skipped: [],
          cartItemCount: 0,
          cartTotal: Money.zero(),
        );
  }

  @override
  Future<void> unlink() async {
    unlinks++;
    status = const WoolworthsLinkStatus.unlinked();
  }
}

/// Woolworths' sign-in, answered by the test: [signInFailure] or
/// [answerFailure] refuse, [asksForCode] makes it ask for a code first.
final class FakeWoolworthsSignIn implements WoolworthsAccountSignIn {
  var asksForCode = false;
  AppFailure? signInFailure;
  AppFailure? answerFailure;
  final signIns = <({String email, String password})>[];
  final answers = <String>[];

  static const refreshToken = 'test-refresh-token';

  @override
  Future<WoolworthsSignInStep> signIn({
    required WoolworthsCognito cognito,
    required String email,
    required String password,
  }) async {
    signIns.add((email: email, password: password));
    if (signInFailure case final failure?) throw failure;
    return asksForCode
        ? WoolworthsCodeAsked(
            cognito: cognito,
            challengeName: 'SMS_MFA',
            session: 'test-session',
            username: email,
            sentTo: '+27*****4567',
          )
        : const WoolworthsSignedIn(refreshToken);
  }

  @override
  Future<WoolworthsSignInStep> answer(
    WoolworthsCodeAsked asked,
    String code,
  ) async {
    answers.add(code);
    if (answerFailure case final failure?) throw failure;
    return const WoolworthsSignedIn(refreshToken);
  }
}
