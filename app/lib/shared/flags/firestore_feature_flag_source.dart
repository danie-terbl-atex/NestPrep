import 'package:cloud_firestore/cloud_firestore.dart';

import '../log/app_log.dart';
import 'feature_flag_source.dart';
import 'feature_flags.dart';

/// The flags at `appConfig/featureFlags`: readable by anybody signed in,
/// written by nobody but the console (the `app_config` rules partial).
final class FirestoreFeatureFlagSource implements FeatureFlagSource {
  FirestoreFeatureFlagSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const collection = 'appConfig';
  static const document = 'featureFlags';

  @override
  Stream<FeatureFlags> watch() => _firestore
      .collection(collection)
      .doc(document)
      .snapshots()
      .map((snapshot) => FeatureFlags.fromStored(snapshot.data()))
      // Signed out, offline on a cold start, or refused: the build's defaults
      // stand, and the reason is logged rather than lost (`ENG-10`).
      .handleError((Object error) {
        AppLog.failure('feature flags', code: 'read', error: error);
      });
}
