import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/data/cart_push_result_parser.dart';
import '../../add_to_checkers/model/cart_push_result.dart';
import '../model/pnp_link_status.dart';
import '../model/pnp_sign_in_result.dart';
import 'pnp_directory.dart';
import 'pnp_failure_mapper.dart';

/// The Pick n Pay callables over the Functions SDK. Each answer is parsed
/// rather than cast (`ENG-09`): an answer of the wrong shape is a Function
/// newer or older than this build, and reads as a failure, not a crash.
final class CallablePnpDirectory implements PnpDirectory {
  const CallablePnpDirectory(this._functions);

  static const statusCallable = 'pnpLinkStatus';
  static const startCallable = 'pnpStartLink';
  static const completeCallable = 'pnpCompleteLink';
  static const pushCallable = 'pnpPushToCart';
  static const unlinkCallable = 'pnpUnlink';

  final FirebaseFunctions _functions;

  @override
  Future<PnpLinkStatus> linkStatus() async =>
      _status(await _call(statusCallable, const {}), statusCallable);

  @override
  Future<Uri> startLink() async {
    final result = await _call(startCallable, const {});
    if (result case {'authorizeUrl': final String url}) {
      final uri = Uri.tryParse(url);
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.host == PnpSignInResult.loginHost) {
        return uri;
      }
    }
    throw _malformed(startCallable);
  }

  @override
  Future<PnpLinkStatus> completeLink({
    required String code,
    required String state,
  }) async => _status(
    await _call(completeCallable, {'code': code, 'state': state}),
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

  PnpLinkStatus _status(Map<Object?, Object?> result, String name) {
    final linked = result['linked'];
    if (linked is! bool) throw _malformed(name);
    return PnpLinkStatus(
      isLinked: linked,
      linkedAt: switch (result['linkedAt']) {
        final String at => DateTime.tryParse(at)?.toUtc(),
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
      throw failureFromPnpCallable(error);
    }
  }
}
