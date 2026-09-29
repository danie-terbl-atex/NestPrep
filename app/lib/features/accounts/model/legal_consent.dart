import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'legal_consent.freezed.dart';
part 'legal_consent.g.dart';

/// Which versions of the terms and the privacy policy an account agreed to,
/// and when — `users/{uid}.legalConsent` (accounts ADR-0005). The rules accept
/// it only in this shape, stamped with the server's time, and never lower than
/// what was agreed before.
@freezed
abstract class LegalConsent with _$LegalConsent {
  const factory LegalConsent({
    required int termsVersion,
    required int privacyVersion,
    @ServerTimestampConverter() DateTime? acceptedAt,
  }) = _LegalConsent;

  const LegalConsent._();

  factory LegalConsent.fromJson(Map<String, Object?> json) =>
      _$LegalConsentFromJson(json);

  /// Whether this acceptance still covers the documents a build ships. Either
  /// one having risen since means asking again.
  bool covers({required int terms, required int privacy}) =>
      termsVersion >= terms && privacyVersion >= privacy;
}
