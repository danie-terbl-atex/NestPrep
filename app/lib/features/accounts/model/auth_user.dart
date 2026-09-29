import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// Who Firebase Auth says the caller is. It is not stored: the account document
/// at `users/{uid}` is (accounts ADR-0001). The uid is the only identifier any
/// rule or Function keys on; the email is shown to the person and never used as
/// a key.
///
/// `emailVerified` is the same claim the callables read off the token, mirrored
/// here so a screen can say why joining a household is refused before the
/// person tries it (accounts ADR-0002). It is never the *enforcement* — that is
/// the server's, and this field is only how the app explains it (`BE-01`).
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    @Default(false) bool emailVerified,
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
