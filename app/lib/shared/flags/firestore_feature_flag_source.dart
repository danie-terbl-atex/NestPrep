import 'package:cloud_firestore/cloud_firestore.dart';

import 'feature_flag_source.dart';
import 'feature_flags.dart';

/// `appConfig/flags`, readable by anybody and written only in the console
/// (foundation ADR-0014). The one place its raw map exists (`ENG-09`).
final class FirestoreFeatureFlagSource implements FeatureFlagSource {
  const FirestoreFeatureFlagSource(this._firestore);

  static const collection = 'appConfig';
  static const document = 'flags';

  final FirebaseFirestore _firestore;

  @override
  Stream<FeatureFlags> watch({required bool defaultOn}) => _firestore
      .collection(collection)
      .doc(document)
      .snapshots()
      .map(
        (snapshot) => FeatureFlags.fromFields(
          snapshot.data() ?? const {},
          defaultOn: defaultOn,
        ),
      );
}
