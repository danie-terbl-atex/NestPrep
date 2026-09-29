import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../log/app_log.dart';
import 'feature_flag_source.dart';
import 'feature_flags.dart';

/// The switches in `appConfig/flags`, which anybody may read and no client may
/// write — they are changed in the Firebase console.
final class FirestoreFeatureFlagSource implements FeatureFlagSource {
  FirestoreFeatureFlagSource(this._firestore, {required this.isDebugBuild});

  static const collection = 'appConfig';
  static const document = 'flags';

  final FirebaseFirestore _firestore;
  final bool isDebugBuild;

  @override
  Stream<FeatureFlags> watch() => _firestore
      .collection(collection)
      .doc(document)
      .snapshots()
      .map(
        (snapshot) => FeatureFlags.fromDocument(
          snapshot.data(),
          isDebugBuild: isDebugBuild,
        ),
      )
      .transform(StreamTransformer.fromHandlers(handleError: _keepTheDefaults));

  /// A switch that cannot be read is a capability at its safe default, not a
  /// broken app: the failure is logged for us, and the defaults stand.
  static void _keepTheDefaults(
    Object error,
    StackTrace stackTrace,
    EventSink<FeatureFlags> sink,
  ) => AppLog.failure(
    'read feature flags',
    code: error is FirebaseException ? error.code : 'unknown',
    error: error,
  );
}
