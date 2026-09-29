import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../shared/log/app_log.dart';
import '../model/push_arrival.dart';
import '../model/push_token.dart';
import 'push_gateway.dart';

/// Firebase Cloud Messaging on the phone (notifications ADR-0001): Android,
/// and iOS through the APNs key uploaded to the Firebase project. The only
/// file in the app that knows `firebase_messaging` exists.
///
/// FCM has no emulator, so this is the same on both backend targets: a token
/// is a way to reach the phone, not household data, and on the emulator
/// target the Functions that would send to it run locally.
final class FirebasePushGateway implements PushGateway {
  FirebasePushGateway(this._messaging);

  /// `MainActivity.kt` answers on this channel; iOS has no channels.
  static const _channels = MethodChannel('io.nullstate.nestprep/notifications');

  final FirebaseMessaging _messaging;

  @override
  PushPlatform? get platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => PushPlatform.android,
    TargetPlatform.iOS => PushPlatform.ios,
    _ => null,
  };

  @override
  Future<PushPermission> permission() async =>
      _read(await _messaging.getNotificationSettings());

  @override
  Future<PushPermission> requestPermission() async {
    final settings = await _messaging.requestPermission();
    // The app shows its own banner while it is open; the phone's would be a
    // second copy of the same words (ADR-0001).
    await _messaging.setForegroundNotificationPresentationOptions();
    return _read(settings);
  }

  @override
  Future<String?> token() async {
    try {
      return await _messaging.getToken();
    } on FirebaseException catch (error) {
      // No token to give: an iPhone with no APNs key behind the project yet,
      // or a phone without Play services. The screen says the phone cannot
      // be reached, which is the truth; nothing else is lost (ADR-0001).
      AppLog.failure('push token', code: error.code, error: error);
      return null;
    }
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<PushArrival> get foregroundArrivals =>
      FirebaseMessaging.onMessage.map(_arrival).where(_isOurs).cast();

  @override
  Stream<PushArrival> get openedArrivals =>
      FirebaseMessaging.onMessageOpenedApp.map(_arrival).where(_isOurs).cast();

  @override
  Future<PushArrival?> launchArrival() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _arrival(message);
  }

  @override
  Future<void> forgetToken() => _messaging.deleteToken();

  @override
  Future<void> prepareChannels(List<PushChannelSpec> channels) async {
    if (platform != PushPlatform.android) return;
    await _channels.invokeMethod<void>('createChannels', [
      for (final channel in channels)
        {
          'id': channel.id,
          'name': channel.name,
          'description': channel.description,
          'important': channel.isImportant,
        },
    ]);
  }

  static bool _isOurs(PushArrival? arrival) => arrival != null;

  static PushArrival? _arrival(RemoteMessage message) => PushArrival.fromData(
    message.data,
    title: message.notification?.title,
    body: message.notification?.body,
  );

  static PushPermission _read(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notAsked,
      };
}
