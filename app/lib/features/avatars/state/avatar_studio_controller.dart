import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../chore_points/data/points_repository.dart';
import '../../chore_points/model/point_balance.dart';
import '../../household/data/household_repository.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import '../data/avatar_photo_store.dart';
import '../data/avatar_repository.dart';
import '../model/avatar_base.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_choice.dart';
import '../model/avatar_library.dart';
import '../model/avatar_purchase.dart';
import '../model/avatar_studio.dart';
import '../model/member_avatar_record.dart';
import 'purchase_outcome.dart';

final class AvatarStudioController extends ChangeNotifier
    with ActionFailureHolder {
  AvatarStudioController({
    required HouseholdRepository householdRepository,
    required AvatarRepository avatarRepository,
    required PointsRepository pointsRepository,
    required AvatarPhotoStore photoStore,
    required this.householdId,
    required this.memberId,
    required this.viewerMemberId,
    required this.viewerUid,
    AvatarLibrary? library,
    this.purchaseWait = const Duration(seconds: 20),
  }) : _households = householdRepository,
       _avatars = avatarRepository,
       _points = pointsRepository,
       _photos = photoStore,
       library = library ?? AvatarLibrary.bundled {
    _subscribe();
  }

  static String hashOf(Uint8List bytes) =>
      sha256.convert(bytes).toString().substring(0, 32);

  final HouseholdRepository _households;
  final AvatarRepository _avatars;
  final PointsRepository _points;
  final AvatarPhotoStore _photos;
  final String householdId;
  final String memberId;
  final String viewerMemberId;
  final String viewerUid;
  final AvatarLibrary library;
  final Duration purchaseWait;

  final _subscriptions = <StreamSubscription<Object?>>[];
  final _purchases = <String, StreamSubscription<AvatarPurchase?>>{};
  final _waits = <String, Timer>{};
  StreamSubscription<PointBalance>? _balanceSubscription;

  Member? _member;
  MemberAvatarRecord? _record;
  bool _shopIsOpen = true;
  bool _creationsOn = true;
  String? _timeZone;
  PointBalance? _balance;
  AvatarChoice? _draft;
  String? _offeredPhoto;
  bool _isSavingPhoto = false;
  final _buying = <String>{};
  PurchaseOutcome? _outcome;
  AsyncState<AvatarStudio> _studio = const AsyncLoading();

  AsyncState<AvatarStudio> get studio => _studio;

  bool get isSavingPhoto => _isSavingPhoto;

  bool isBuying(String accessoryId) => _buying.contains(accessoryId);

  PurchaseOutcome? get outcome => _outcome;

  AvatarStudio? get _current => switch (_studio) {
    AsyncData(:final value) => value,
    _ => null,
  };

  void _subscribe() {
    _listen(_households.watchMember(householdId, memberId), (member) {
      if (member == null) {
        _studio = const AsyncFailure(NotFoundFailure());
        notifyListeners();
        return;
      }
      final wasKid = _member?.role == MemberRole.kid;
      _member = member;
      if (member.role == MemberRole.kid && !wasKid) _watchBalance();
      _publish();
    });
    _listen(_households.watchHousehold(householdId), (household) {
      _shopIsOpen = household?.avatarShop ?? true;
      _creationsOn = household?.avatarCreationsOn ?? true;
      _timeZone = household?.timeZone;
      _publish();
    });
    _listen(_avatars.watch(householdId, memberId), (record) {
      _record = record;
      if (_draft != null && record.choice == _draft) _draft = null;
      final offered = _offeredPhoto;
      if (offered != null &&
          record.pendingPhoto == null &&
          record.ownedImages.contains(offered)) {
        _offeredPhoto = null;
      }
      _publish();
    });
  }

  void _watchBalance() {
    unawaited(_balanceSubscription?.cancel());
    _balanceSubscription = _points
        .watchBalance(householdId, memberId)
        .listen(
          (balance) {
            _balance = balance;
            _publish();
          },
          onError: (Object _) {
            _balance = null;
            _publish();
          },
        );
  }

  void _listen<T>(Stream<T> stream, void Function(T value) onValue) {
    _subscriptions.add(
      stream.listen(
        onValue,
        onError: (Object error) {
          _studio = AsyncFailure(
            error is AppFailure ? error : UnknownFailure(error),
          );
          notifyListeners();
        },
      ),
    );
  }

  void _publish() {
    final (member, record) = (_member, _record);
    if (member == null || record == null) return;
    _studio = AsyncData(
      AvatarStudio(
        member: member,
        record: record,
        choice: _draft ?? record.choice ?? _choiceFromLook(member),
        shopIsOpen: _shopIsOpen,
        creationsOn: _creationsOn,
        timeZone: _timeZone ?? 'UTC',
        library: library,
        balance: _balance,
        offeredPhoto:
            _offeredPhoto ?? (_draft == null ? record.pendingPhoto : null),
      ),
    );
    notifyListeners();
  }

  static AvatarChoice _choiceFromLook(Member member) => switch (member.look) {
    final look? => AvatarChoice(base: look.base, wear: look.wear),
    null => const AvatarChoice(),
  };

  Future<void> pickNestling(String name) => _choose(
    (studio) => studio.choice.copyWith(
      base: PresetBase(name),
      stage: studio.isKid ? null : studio.stage,
    ),
  );

  Future<void> pickStage(int stage) => _choose(
    (studio) =>
        studio.isKid ? studio.choice : studio.choice.copyWith(stage: stage),
  );

  Future<void> useImage(String hash) =>
      _choose((studio) => studio.choice.copyWith(base: ImageBase(hash)));

  Future<void> useInitial() =>
      _choose((studio) => studio.choice.copyWith(base: const InitialBase()));

  Future<void> wear(AvatarSlot slot, String? accessoryId) =>
      _choose((studio) => studio.choice.wearing(slot, accessoryId));

  Future<void> _choose(AvatarChoice Function(AvatarStudio studio) next) async {
    final studio = _current;
    if (studio == null) return;
    final choice = next(studio);
    _draft = choice;
    _offeredPhoto = null;
    _publish();
    await runAction(() async {
      try {
        await _avatars.choose(
          householdId: householdId,
          memberId: memberId,
          choice: choice,
          byMemberId: viewerMemberId,
        );
      } on AppFailure {
        if (_draft == choice) _draft = null;
        _publish();
        rethrow;
      }
    });
  }

  Future<void> savePhoto(Uint8List jpeg) async {
    if (_isSavingPhoto) return;
    _isSavingPhoto = true;
    notifyListeners();
    await runAction(() async {
      final hash = hashOf(jpeg);
      try {
        await _photos.upload(
          householdId: householdId,
          memberId: memberId,
          hash: hash,
          uploaderUid: viewerUid,
          bytes: jpeg,
        );
        await _avatars.offerPhoto(
          householdId: householdId,
          memberId: memberId,
          hash: hash,
          choice: _current?.choice ?? const AvatarChoice(),
          byMemberId: viewerMemberId,
        );
        _offeredPhoto = hash;
      } finally {
        _isSavingPhoto = false;
        _publish();
      }
    });
  }

  Future<void> buy(AvatarAccessory accessory) async {
    if (_buying.contains(accessory.id)) return;
    _buying.add(accessory.id);
    _outcome = null;
    notifyListeners();
    await runAction(() async {
      try {
        final purchaseId = await _avatars
            .buy(
              householdId: householdId,
              memberId: memberId,
              accessoryId: accessory.id,
              byMemberId: viewerMemberId,
            )
            .timeout(purchaseWait);
        _follow(purchaseId, accessory);
      } on TimeoutException {
        _tooSlow(accessory);
      } on AppFailure {
        _buying.remove(accessory.id);
        notifyListeners();
        rethrow;
      }
    });
  }

  void _follow(String purchaseId, AvatarAccessory accessory) {
    _waits[purchaseId] = Timer(purchaseWait, () {
      _waits.remove(purchaseId);
      unawaited(_purchases.remove(purchaseId)?.cancel());
      _tooSlow(accessory);
    });
    _purchases[purchaseId] = _avatars
        .watchPurchase(householdId, purchaseId)
        .listen(
          (purchase) {
            if (purchase == null || purchase.isWaiting) return;
            _waits.remove(purchaseId)?.cancel();
            unawaited(_purchases.remove(purchaseId)?.cancel());
            _buying.remove(accessory.id);
            _outcome = PurchaseOutcome(
              accessory: accessory,
              isOwned: purchase.status == PurchaseStatus.owned,
              reason: purchase.reason,
            );
            notifyListeners();
            if (purchase.status == PurchaseStatus.owned) {
              unawaited(wear(accessory.slot, accessory.id));
            }
          },
          onError: (Object error) {
            _waits.remove(purchaseId)?.cancel();
            unawaited(_purchases.remove(purchaseId)?.cancel());
            _buying.remove(accessory.id);
            recordFailure(error is AppFailure ? error : UnknownFailure(error));
          },
        );
  }

  void _tooSlow(AvatarAccessory accessory) {
    _buying.remove(accessory.id);
    _outcome = PurchaseOutcome(
      accessory: accessory,
      isOwned: false,
      isTooSlow: true,
    );
    notifyListeners();
  }

  void dismissOutcome() {
    if (_outcome == null) return;
    _outcome = null;
    notifyListeners();
  }

  Future<void> retry() async {
    await _cancel();
    _studio = const AsyncLoading();
    _member = null;
    _record = null;
    notifyListeners();
    _subscribe();
  }

  Future<void> _cancel() async {
    final subscriptions = [
      ..._subscriptions,
      ..._purchases.values,
      ?_balanceSubscription,
    ];
    _subscriptions.clear();
    _purchases.clear();
    for (final wait in _waits.values) {
      wait.cancel();
    }
    _waits.clear();
    _balanceSubscription = null;
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
