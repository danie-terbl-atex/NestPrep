import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/change_request.dart';
import '../model/co_parent_link.dart';
import '../model/handover_note.dart';
import 'two_homes_repository.dart';

/// The household's mirrors of its links, read under `coparent.rules`
/// (household ADR-0004). Written only by the co-parenting Functions, so every
/// `toJson` here refuses — a client write would be refused by the rules, and
/// this makes the attempt impossible to write.
final class FirestoreTwoHomesRepository implements TwoHomesRepository {
  FirestoreTwoHomesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const households = 'households';
  static const links = 'coParentLinks';
  static const handovers = 'handovers';
  static const requests = 'requests';

  /// A household has a handful of links in its life; this is generous.
  static const linkListen = 20;

  /// Twelve weeks of handovers either side is more than a screen shows.
  static const handoverListen = 60;

  /// The history a link screen shows.
  static const requestListen = 50;

  static Never _readOnly(Object _) =>
      throw UnsupportedError('written only by the co-parenting Functions');

  CollectionReference<Map<String, dynamic>> _links(String householdId) =>
      _firestore.collection(households).doc(householdId).collection(links);

  CollectionReference<CoParentLink> _typedLinks(String householdId) =>
      typedCollection(
        _links(householdId),
        fromJson: CoParentLink.fromJson,
        toJson: _readOnly,
      );

  CollectionReference<HandoverNote> _handovers(
    String householdId,
    String linkId,
  ) => typedCollection(
    _links(householdId).doc(linkId).collection(handovers),
    fromJson: HandoverNote.fromJson,
    toJson: _readOnly,
  );

  @override
  Stream<List<CoParentLink>> watchLinks(String householdId) => _list(
    _typedLinks(
      householdId,
    ).orderBy('createdAt', descending: true).limit(linkListen).snapshots(),
  );

  @override
  Stream<CoParentLink?> watchLink({
    required String householdId,
    required String linkId,
  }) => _typedLinks(householdId)
      .doc(linkId)
      .snapshots()
      .map((snapshot) => snapshot.data())
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<HandoverNote>> watchHandovers({
    required String householdId,
    required String linkId,
    required CalendarDate from,
    required CalendarDate to,
  }) => _list(
    _handovers(householdId, linkId)
        .where('date', isGreaterThanOrEqualTo: from.iso)
        .where('date', isLessThanOrEqualTo: to.iso)
        .orderBy('date')
        .limit(handoverListen)
        .snapshots(),
  );

  @override
  Stream<HandoverNote?> watchHandover({
    required String householdId,
    required String linkId,
    required CalendarDate date,
  }) => _handovers(householdId, linkId)
      .doc(date.iso)
      .snapshots()
      .map((snapshot) => snapshot.data())
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<ChangeRequest>> watchRequests({
    required String householdId,
    required String linkId,
  }) => _list(
    typedCollection(
      _links(householdId).doc(linkId).collection(requests),
      fromJson: ChangeRequest.fromJson,
      toJson: _readOnly,
    ).orderBy('createdAt', descending: true).limit(requestListen).snapshots(),
  );

  /// Every read here is bounded where it is built, beside its `.limit`
  /// (`BE-08`); this only unwraps the documents and translates a failure.
  Stream<List<T>> _list<T>(Stream<QuerySnapshot<T>> snapshots) => snapshots
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));
}
