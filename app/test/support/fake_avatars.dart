import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/avatars/data/avatar_photo_picker.dart';
import 'package:nestprep/features/avatars/data/avatar_photo_store.dart';
import 'package:nestprep/features/avatars/data/avatar_repository.dart';
import 'package:nestprep/features/avatars/data/avatar_seen_stage_store.dart';
import 'package:nestprep/features/avatars/model/avatar_buddy.dart';
import 'package:nestprep/features/avatars/model/avatar_choice.dart';
import 'package:nestprep/features/avatars/model/avatar_creation.dart';
import 'package:nestprep/features/avatars/model/avatar_keepsake.dart';
import 'package:nestprep/features/avatars/model/avatar_purchase.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

final class FakeAvatarRepository implements AvatarRepository {
  FakeAvatarRepository([this.record = MemberAvatarRecord.none]);

  MemberAvatarRecord record;
  final _records = StreamController<MemberAvatarRecord>.broadcast();
  final _purchases = StreamController<AvatarPurchase>.broadcast();
  AppFailure? failWritesWith;
  bool purchasesNeverLand = false;

  final chosen = <({String memberId, AvatarChoice choice, String by})>[];
  final offered = <({String memberId, String hash, AvatarChoice choice})>[];
  final bought = <({String id, String memberId, String accessoryId})>[];
  final shopSwitched = <bool>[];
  final creationsSwitched = <bool>[];
  final requested =
      <
        ({
          String id,
          String memberId,
          CreationRecipe recipe,
          String by,
          CreationStyle? style,
          AvatarBuddy? buddy,
          String? extra,
          String? inboxId,
        })
      >[];
  final keepsakeDeletes = <({String keepsakeId, String by})>[];
  bool creationsNeverLand = false;
  var _creationIds = 0;
  List<AvatarCreation> recentCreations = const [];
  final _creations = StreamController<AvatarCreation>.broadcast();
  final _recent = StreamController<List<AvatarCreation>>.broadcast();
  final keepsakes = <String, List<AvatarKeepsake>>{};
  final _keepsakes = StreamController<void>.broadcast();

  void settleCreation(AvatarCreation creation) => _creations.add(creation);

  void emitRecent(List<AvatarCreation> creations) {
    recentCreations = creations;
    _recent.add(creations);
  }

  void emitKeepsakes(String memberId, List<AvatarKeepsake> shelf) {
    keepsakes[memberId] = shelf;
    _keepsakes.add(null);
  }

  void emit(MemberAvatarRecord next) {
    record = next;
    _records.add(next);
  }

  void settle(AvatarPurchase purchase) => _purchases.add(purchase);

  Future<void> close() async {
    await _records.close();
    await _purchases.close();
    await _creations.close();
    await _recent.close();
    await _keepsakes.close();
  }

  @override
  Stream<MemberAvatarRecord> watch(String householdId, String memberId) =>
      Stream.multi((listener) {
        listener.add(record);
        final subscription = _records.stream.listen(
          listener.add,
          onError: listener.addError,
        );
        listener.onCancel = subscription.cancel;
      });

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }

  @override
  Future<void> choose({
    required String householdId,
    required String memberId,
    required AvatarChoice choice,
    required String byMemberId,
  }) async {
    _refuseIfAsked();
    chosen.add((memberId: memberId, choice: choice, by: byMemberId));
  }

  @override
  Future<void> offerPhoto({
    required String householdId,
    required String memberId,
    required String hash,
    required AvatarChoice choice,
    required String byMemberId,
  }) async {
    _refuseIfAsked();
    offered.add((memberId: memberId, hash: hash, choice: choice));
  }

  @override
  Future<String> buy({
    required String householdId,
    required String memberId,
    required String accessoryId,
    required String byMemberId,
  }) async {
    _refuseIfAsked();
    if (purchasesNeverLand) return Completer<String>().future;
    final id = 'purchase-${bought.length + 1}';
    bought.add((id: id, memberId: memberId, accessoryId: accessoryId));
    return id;
  }

  @override
  Stream<AvatarPurchase?> watchPurchase(
    String householdId,
    String purchaseId,
  ) => _purchases.stream.where((purchase) => purchase.id == purchaseId);

  @override
  Future<void> setShop({
    required String householdId,
    required bool isOpen,
  }) async {
    _refuseIfAsked();
    shopSwitched.add(isOpen);
  }

  @override
  Future<void> setCreations({
    required String householdId,
    required bool isOn,
  }) async {
    _refuseIfAsked();
    creationsSwitched.add(isOn);
  }

  @override
  String newCreationId(String householdId) =>
      'creation-${++_creationIds}-abcdefgh';

  @override
  Future<void> requestCreation({
    required String householdId,
    required String creationId,
    required String memberId,
    required CreationRecipe recipe,
    required String byMemberId,
    CreationStyle? style,
    AvatarBuddy? buddy,
    String? extra,
    String? inboxId,
  }) async {
    _refuseIfAsked();
    if (creationsNeverLand) return Completer<void>().future;
    requested.add((
      id: creationId,
      memberId: memberId,
      recipe: recipe,
      by: byMemberId,
      style: style,
      buddy: buddy,
      extra: extra,
      inboxId: inboxId,
    ));
  }

  @override
  Stream<AvatarCreation?> watchCreation(
    String householdId,
    String creationId,
  ) => _creations.stream.where((creation) => creation.id == creationId);

  @override
  Stream<List<AvatarCreation>> watchRecentCreations(String householdId) =>
      Stream.multi((listener) {
        listener.add(recentCreations);
        final subscription = _recent.stream.listen(
          listener.add,
          onError: listener.addError,
        );
        listener.onCancel = subscription.cancel;
      });

  @override
  Stream<List<AvatarKeepsake>> watchKeepsakes(
    String householdId,
    String memberId,
  ) => Stream.multi((listener) {
    listener.add(keepsakes[memberId] ?? const []);
    final subscription = _keepsakes.stream.listen(
      (_) => listener.add(keepsakes[memberId] ?? const []),
      onError: listener.addError,
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<void> deleteKeepsake({
    required String householdId,
    required String keepsakeId,
    required String byMemberId,
  }) async {
    _refuseIfAsked();
    keepsakeDeletes.add((keepsakeId: keepsakeId, by: byMemberId));
  }
}

final class FakeAvatarPhotoStore implements AvatarPhotoStore {
  final stored = <String, Uint8List>{};
  final uploaded = <({String hash, String uploaderUid})>[];
  final atPath = <String, Uint8List>{};
  final references =
      <({String memberId, String inboxId, String uploaderUid, int bytes})>[];
  AppFailure? failReferencesWith;

  @override
  Uint8List? keptAt(String path) => atPath[path];

  @override
  Future<Uint8List?> readAt(String path) async => atPath[path];

  @override
  Future<void> uploadReference({
    required String householdId,
    required String memberId,
    required String inboxId,
    required String uploaderUid,
    required Uint8List bytes,
  }) async {
    final failure = failReferencesWith;
    if (failure != null) throw failure;
    references.add((
      memberId: memberId,
      inboxId: inboxId,
      uploaderUid: uploaderUid,
      bytes: bytes.length,
    ));
  }

  @override
  Uint8List? kept({
    required String householdId,
    required String memberId,
    required String hash,
  }) => stored[hash];

  @override
  Future<Uint8List?> read({
    required String householdId,
    required String memberId,
    required String hash,
  }) async => stored[hash];

  @override
  Future<void> upload({
    required String householdId,
    required String memberId,
    required String hash,
    required String uploaderUid,
    required Uint8List bytes,
  }) async {
    stored[hash] = bytes;
    uploaded.add((hash: hash, uploaderUid: uploaderUid));
  }
}

final class FakeAvatarPhotoPicker implements AvatarPhotoPicker {
  FakeAvatarPhotoPicker([this.photo]);

  Uint8List? photo;
  final asked = <AvatarPhotoSource>[];
  final facing = <bool>[];

  @override
  Future<Uint8List?> pick(
    AvatarPhotoSource source, {
    bool facingUser = true,
  }) async {
    asked.add(source);
    facing.add(facingUser);
    return photo;
  }
}

final class FakeAvatarSeenStageStore implements AvatarSeenStageStore {
  FakeAvatarSeenStageStore([Map<String, int>? stages]) : stages = stages ?? {};

  final Map<String, int> stages;

  @override
  Future<int?> seen(String householdId, String memberId) async =>
      stages[memberId];

  @override
  Future<void> markSeen(String householdId, String memberId, int stage) async {
    stages[memberId] = stage;
  }
}
