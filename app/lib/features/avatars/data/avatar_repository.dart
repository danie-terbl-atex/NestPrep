import '../model/avatar_buddy.dart';
import '../model/avatar_choice.dart';
import '../model/avatar_creation.dart';
import '../model/avatar_keepsake.dart';
import '../model/avatar_purchase.dart';
import '../model/member_avatar_record.dart';

abstract interface class AvatarRepository {
  Stream<MemberAvatarRecord> watch(String householdId, String memberId);

  Future<void> choose({
    required String householdId,
    required String memberId,
    required AvatarChoice choice,
    required String byMemberId,
  });

  Future<void> offerPhoto({
    required String householdId,
    required String memberId,
    required String hash,
    required AvatarChoice choice,
    required String byMemberId,
  });

  Future<String> buy({
    required String householdId,
    required String memberId,
    required String accessoryId,
    required String byMemberId,
  });

  Stream<AvatarPurchase?> watchPurchase(String householdId, String purchaseId);

  Future<void> setShop({required String householdId, required bool isOpen});

  Future<void> setCreations({required String householdId, required bool isOn});

  String newCreationId(String householdId);

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
  });

  Stream<AvatarCreation?> watchCreation(String householdId, String creationId);

  Stream<List<AvatarCreation>> watchRecentCreations(String householdId);

  Stream<List<AvatarKeepsake>> watchKeepsakes(
    String householdId,
    String memberId,
  );

  Future<void> deleteKeepsake({
    required String householdId,
    required String keepsakeId,
    required String byMemberId,
  });
}
