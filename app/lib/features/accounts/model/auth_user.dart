import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// Who Firebase Auth says the caller is. It is not stored: the account document
/// at `users/{uid}` is (accounts ADR-0001). The uid is the only identifier any
/// rule or Function keys on; the email is shown to the person and never used as
/// a key.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) = _AuthUser;

  const AuthUser._();

  /// What to call this person before they have told us anything else.
  String get bestName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final localPart = email.split('@').first;
    return localPart.isEmpty ? email : localPart;
  }
}
