import '../model/push_token.dart';

/// The phones an account's pushes go to (notifications ADR-0001). Only its own
/// account writes one; the server forgets a token FCM calls dead, and signing
/// out deletes the phone's token so the next send finds it dead too.
abstract interface class PushTokenRepository {
  Future<void> register(String uid, PushToken token);
}
