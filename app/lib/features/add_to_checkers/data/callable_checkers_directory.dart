import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/cart_push_result.dart';
import '../model/checkers_link_status.dart';
import 'cart_push_result_parser.dart';
import 'checkers_directory.dart';
import 'checkers_failure_mapper.dart';

/// The Checkers callables over the Functions SDK. Each answer is parsed rather
/// than cast (`ENG-09`): an answer of the wrong shape is a Function newer or
/// older than this build, and reads as a failure rather than a crash.
final class CallableCheckersDirectory implements CheckersDirectory {
  const CallableCheckersDirectory(this._functions);

  static const statusCallable = 'checkersLinkStatus';
  static const requestOtpCallable = 'checkersRequestOtp';
  static const verifyOtpCallable = 'checkersVerifyOtp';
  static const pushCallable = 'checkersPushToCart';
  static const unlinkCallable = 'checkersUnlink';

  final FirebaseFunctions _functions;

  @override
  Future<CheckersLinkStatus> linkStatus() async =>
      _status(await _call(statusCallable, const {}), statusCallable);

  @override
  Future<String> requestOtp(String mobile) async {
    final result = await _call(requestOtpCallable, {'mobile': mobile});
    if (result case {'sent': true, 'mobileMasked': final String masked}) {
      return masked;
    }
    throw _malformed(requestOtpCallable);
  }

  @override
  Future<CheckersLinkStatus> verifyOtp(String code) async => _status(
    await _call(verifyOtpCallable, {'code': code}),
    verifyOtpCallable,
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

  CheckersLinkStatus _status(Map<Object?, Object?> result, String name) {
    final linked = result['linked'];
    if (linked is! bool) throw _malformed(name);
    return CheckersLinkStatus(
      isLinked: linked,
      expiresAt: switch (result['expiresAt']) {
        final String at => DateTime.tryParse(at)?.toUtc(),
        _ => null,
      },
      mobileMasked: switch (result['mobileMasked']) {
        final String masked when masked.isNotEmpty => masked,
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
      throw failureFromCheckersCallable(error);
    }
  }
}
