import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/accounts/model/session.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/notifications/data/callable_notification_directory.dart';
import '../features/notifications/data/firebase_push_gateway.dart';
import '../features/notifications/data/firestore_notification_repository.dart';
import '../features/notifications/data/firestore_push_token_repository.dart';
import '../features/notifications/data/notification_directory.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/data/push_gateway.dart';
import '../features/notifications/data/push_token_repository.dart';
import '../features/notifications/state/push_registrar.dart';
import '../shared/async/async_state.dart';

/// Notifications' part of the app-wide graph (notifications ADR-0001): the
/// inbox and settings, the phone's push service, its token, the one callable,
/// and the registrar that follows the session — above every route, because a
/// phone stays registered whichever screen is open. Each behind its
/// interface, so a widget test substitutes a fake.
///
/// Its own list, spread into `appProviders` after the session, so the shared
/// file changes by one line.
List<SingleChildWidget> notificationsProviders() => [
  Provider<NotificationRepository>(
    create: (context) =>
        FirestoreNotificationRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<PushTokenRepository>(
    create: (context) =>
        FirestorePushTokenRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<NotificationDirectory>(
    create: (context) =>
        CallableNotificationDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<PushGateway>(
    create: (context) => FirebasePushGateway(FirebaseMessaging.instance),
  ),
  ChangeNotifierProvider<PushRegistrar>(
    create: (context) {
      final session = context.read<SessionController>();
      return PushRegistrar(
        gateway: context.read<PushGateway>(),
        tokens: context.read<PushTokenRepository>(),
        session: session,
        signedInUid: () => _pushUid(session),
      );
    },
  ),
];

/// Whose phone this is: an account, or a kid device — whose tablet hears
/// about its own lunch and chores (notifications ADR-0003) — or nobody.
String _pushUid(SessionController session) => switch (session.session) {
  AsyncData(value: SignedIn(:final uid)) => uid,
  AsyncData(value: KidSignedIn(:final uid)) => uid,
  _ => '',
};
