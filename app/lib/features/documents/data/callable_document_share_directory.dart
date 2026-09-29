import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/share_lifetime.dart';
import '../model/share_request.dart';
import '../model/shared_link.dart';
import 'document_failure_mapper.dart';
import 'document_share_directory.dart';

/// `createDocumentShare` and `revokeDocumentShare` (documents ADR-0006). The
/// answer is parsed here, at the edge, and never cast (`ENG-09`).
final class CallableDocumentShareDirectory implements DocumentShareDirectory {
  const CallableDocumentShareDirectory(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<SharedLink> create(ShareRequest request) async {
    final lifetime = request.lifetime;
    final answer = await _call('createDocumentShare', {
      'householdId': request.householdId,
      'ownerMemberId': request.ownerMemberId,
      'documentId': request.documentId,
      'lifetimeHours': switch (lifetime) {
        HoursLifetime(:final hours) => hours,
        ShiftLifetime() => null,
      },
      'shiftId': switch (lifetime) {
        HoursLifetime() => null,
        ShiftLifetime(:final shiftId) => shiftId,
      },
      'pin': request.pin,
    });
    return parseSharedLink(answer);
  }

  @override
  Future<void> revoke({
    required String householdId,
    required String shareId,
  }) async {
    await _call('revokeDocumentShare', {
      'householdId': householdId,
      'shareId': shareId,
    });
  }

  Future<Object?> _call(String name, Map<String, Object?> payload) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Object?>(payload);
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      throw failureFromDocumentCallable(error);
    }
  }
}

/// The callable's answer, or `UnknownFailure` when it is not the shape agreed
/// — a link the app cannot read is not a link it can hand to a person.
SharedLink parseSharedLink(Object? answer) {
  if (answer case {
    'shareId': final String shareId,
    'url': final String url,
    'expiresAt': final String expiresAt,
  }) {
    final uri = Uri.tryParse(url);
    final ends = DateTime.tryParse(expiresAt);
    if (uri != null && uri.hasScheme && ends != null) {
      return SharedLink(shareId: shareId, url: uri, expiresAt: ends.toUtc());
    }
  }
  throw UnknownFailure(FormatException('not a shared link', answer));
}
