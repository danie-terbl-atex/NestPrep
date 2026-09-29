import 'dart:async';

import '../../household/model/member.dart';
import '../data/vault_repository.dart';
import '../model/vault_document.dart';
import '../model/vault_grant.dart';
import '../model/vault_shelf.dart';

/// Keeps one listener open per vault this person may read, and one per vault
/// they manage for its grants — and changes that set as grants arrive and go
/// (documents ADR-0002).
///
/// Which vaults to listen to mirrors the rules only so as not to ask for what
/// they would refuse: the viewer's own, every one for an admin, and the ones
/// whose grant to this viewer exists. A separate class from the controller
/// because a changing set of subscriptions is its own thing to get wrong.
final class VaultListeners {
  VaultListeners({
    required this._repository,
    required this.householdId,
    required this.members,
    required this.viewerMemberId,
    required this.viewerUid,
    required this.isAdmin,
    required this._onShelf,
    required this._onError,
  });

  final VaultRepository _repository;
  final String householdId;
  final List<Member> members;
  final String viewerMemberId;
  final String viewerUid;
  final bool isAdmin;
  final void Function(VaultShelf shelf) _onShelf;
  final void Function(Object error) _onError;

  final _grantedToMe = <String>{};

  /// The vaults whose grant-to-me listener has answered at least once.
  final _answered = <String>{};
  final _documents = <String, List<VaultDocument>>{};
  final _grants = <String, List<VaultGrant>>{};
  final _subscriptions = <String, StreamSubscription<Object?>>{};

  Set<String> get _managed => {
    for (final member in members)
      if (isAdmin || member.id == viewerMemberId) member.id,
  };

  Set<String> get _readable => {..._managed, ..._grantedToMe};

  void start() {
    for (final id in _managed) {
      _listen('grants:$id', _grantsOf(id), (grants) => _grants[id] = grants);
    }
    if (!isAdmin) {
      for (final member in members) {
        if (member.id == viewerMemberId) continue;
        _listen(
          'grant-to-me:${member.id}',
          _repository.watchGrantTo(
            householdId: householdId,
            ownerMemberId: member.id,
            granteeUid: viewerUid,
          ),
          (isGranted) {
            _answered.add(member.id);
            isGranted
                ? _grantedToMe.add(member.id)
                : _grantedToMe.remove(member.id);
          },
        );
      }
    }
    _syncVaults();
    // Somebody with nothing to listen to still gets an answer: an empty shelf.
    _publish();
  }

  Future<void> stop() async {
    final open = _subscriptions.values.toList();
    _subscriptions.clear();
    _grantedToMe.clear();
    _answered.clear();
    _documents.clear();
    _grants.clear();
    await Future.wait(open.map((subscription) => subscription.cancel()));
  }

  Stream<List<VaultGrant>> _grantsOf(String memberId) => _repository
      .watchGrants(householdId: householdId, ownerMemberId: memberId);

  void _listen<T>(String key, Stream<T> stream, void Function(T value) apply) {
    _subscriptions[key] = stream.listen((value) {
      apply(value);
      if (key.startsWith('grant-to-me:')) _syncVaults();
      _publish();
    }, onError: _onError);
  }

  /// Opens a listener for each vault that became readable and closes the ones
  /// that stopped being — a revoked grant takes its documents off the screen.
  void _syncVaults() {
    final readable = _readable;
    for (final id in readable) {
      if (_subscriptions.containsKey('vault:$id')) continue;
      _listen(
        'vault:$id',
        _repository.watchVault(householdId: householdId, ownerMemberId: id),
        (documents) => _documents[id] = documents,
      );
    }
    final gone = [
      for (final key in _subscriptions.keys)
        if (key.startsWith('vault:') && !readable.contains(key.substring(6)))
          key,
    ];
    for (final key in gone) {
      unawaited(_subscriptions.remove(key)?.cancel());
      _documents.remove(key.substring(6));
    }
  }

  /// Publishes once every readable vault, and every awaited grant, has said
  /// something — never a half-loaded shelf that shows a vault as empty.
  void _publish() {
    final readable = _readable;
    final ready =
        readable.every(_documents.containsKey) &&
        _managed.every(_grants.containsKey) &&
        (isAdmin ||
            members
                .where((member) => member.id != viewerMemberId)
                .every((member) => _answered.contains(member.id)));
    if (!ready) return;
    _onShelf(
      VaultShelf(
        owners: [
          for (final member in members)
            if (readable.contains(member.id)) member,
        ],
        documents: Map.of(_documents),
        grants: Map.of(_grants),
        managed: _managed,
      ),
    );
  }
}
