import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/data/cart_push_result_parser.dart';
import '../../add_to_checkers/model/cart_push_result.dart';
import '../model/woolworths_link_status.dart';
import '../model/woolworths_sign_in.dart';
import 'woolworths_directory.dart';
import 'woolworths_failure_mapper.dart';

/// The Woolworths callables over the Functions SDK. Each answer is parsed
/// rather than cast (`ENG-09`): an answer of the wrong shape is a Function
/// newer or older than this build, and reads as a failure, not a crash.
final class CallableWoolworthsDirectory implements WoolworthsDirectory {
  const CallableWoolworthsDirectory(this._functions);

  static const statusCallable = 'woolworthsLinkStatus';
  static const startCallable = 'woolworthsStartLink';
  static const completeCallable = 'woolworthsCompleteLink';
  static const pushCallable = 'woolworthsPushToCart';
  static const unlinkCallable = 'woolworthsUnlink';

  final FirebaseFunctions _functions;

  @override
  Future<WoolworthsLinkStatus> linkStatus() async =>
      _status(await _call(statusCallable, const {}), statusCallable);

  @override
  Future<WoolworthsCognito> startLink() async {
    final result = await _call(startCallable, const {});
    if (result case {
      'clientId': final String clientId,
      'region': final String region,
    }) {
      final cognito = WoolworthsCognito.tryFrom(
        clientId: clientId,
        region: region,
      );
      if (cognito != null) return cognito;
    }
    throw _malformed(startCallable);
  }

  @override
  Future<WoolworthsLinkStatus> completeLink({
    required String refreshToken,
  }) async => _status(
    await _call(completeCallable, {'refreshToken': refreshToken}),
    completeCallable,
  );

  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  }) async {
    final result = await _call(pushCallable, {
      'householdId': householdId,
      'itemIds': itemIds,
      if (quantities.isNotEmpty) 'quantities': quantities,
    });
    return CartPushResultParser.parse(result) ??
        (throw _malformed(pushCallable));
  }

  @override
  Future<void> unlink() async {
    await _call(unlinkCallable, const {});
  }

  WoolworthsLinkStatus _status(Map<Object?, Object?> result, String name) {
    final linked = result['linked'];
    if (linked is! bool) throw _malformed(name);
    return WoolworthsLinkStatus(
      isLinked: linked,
      linkedAt: switch (result['linkedAt']) {
        final String at => DateTime.tryParse(at)?.toUtc(),
        _ => null,
      },
      emailMasked: switch (result['emailMasked']) {
        final String email when email.isNotEmpty => email,
        _ => null,
      },
    );
  }

  UnknownFailure _malformed(String name) =>
      UnknownFailure(StateError('$name answered an unexpected shape'));

  Future<Map<Object?, Object?>> _call(
    String name,
    Map<String, Object?> payload,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Object?>(payload);
      final data = result.data;
      return data is Map ? data : const {};
    } on FirebaseFunctionsException catch (error) {
      throw failureFromWoolworthsCallable(error);
    }
  }
}
