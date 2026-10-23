import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/log/app_log.dart';
import '../../groceries/model/product_match.dart';
import '../model/aisle_shelf.dart';
import '../model/lunch_aisle.dart';
import 'lunch_aisle_source.dart';

/// `appConfig/lunchAisle`, written only in the console, readable by anybody
/// signed in (lunch-box ADR-0013). Its `shelves` replace Checkers' list
/// compiled into the app when Checkers changes its lunchbox page, and its
/// `pnpShelves` Pick n Pay's (lunch-box ADR-0026); until somebody writes
/// it, or when it cannot be read, the compiled list is the answer — the
/// shelves are a head start, never a reason for planning to fail.
final class FirestoreLunchAisleSource implements LunchAisleSource {
  const FirestoreLunchAisleSource(this._firestore);

  static const collection = 'appConfig';
  static const document = 'lunchAisle';

  final FirebaseFirestore _firestore;

  @override
  Future<List<AisleShelf>> shelves(ProductRetailer shop) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .doc(document)
          .get();
      return LunchAisle.fromFields(snapshot.data() ?? const {}, shop: shop) ??
          LunchAisle.defaultsFor(shop);
    } on FirebaseException catch (error) {
      AppLog.failure('read lunch aisle', code: error.code, error: error);
      return LunchAisle.defaultsFor(shop);
    }
  }
}
