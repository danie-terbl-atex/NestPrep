import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../model/packing_preference.dart';
import 'packing_choice_store.dart';

/// The packing choices in `flutter_secure_storage`, the app's one key-value
/// store on the phone, as the Checkers area is. Nothing here is secret.
final class SecureStoragePackingChoiceStore implements PackingChoiceStore {
  SecureStoragePackingChoiceStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'nestprep.planWeekPacking.';

  final FlutterSecureStorage _storage;

  @override
  Future<PackingChoice?> read(String householdId) async {
    try {
      final stored = await _storage.read(key: '$_prefix$householdId');
      return stored == null ? null : fromStored(stored);
    } on PlatformException catch (error) {
      AppLog.failure('plan week packing read', code: error.code, error: error);
      return null;
    }
  }

  @override
  Future<void> write(String householdId, PackingChoice choice) async {
    try {
      await _storage.write(
        key: '$_prefix$householdId',
        value: toStored(choice),
      );
    } on PlatformException catch (error) {
      AppLog.failure('plan week packing write', code: error.code, error: error);
    }
  }

  static String toStored(PackingChoice choice) => jsonEncode({
    'preferences': wireNames(PackingPreference.values, choice.preferences),
    'slots': wireNames(LunchSlot.values, choice.slots),
  });

  /// Names this build does not know are dropped; a choice with no
  /// compartment left is no choice.
  static PackingChoice? fromStored(String stored) {
    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final slots = _named(decoded['slots'], LunchSlot.values);
    if (slots.isEmpty) return null;
    return (
      preferences: _named(decoded['preferences'], PackingPreference.values),
      slots: slots,
    );
  }

  static Set<T> _named<T extends Enum>(Object? names, List<T> values) => {
    if (names is List)
      for (final value in values)
        if (names.contains(value.name)) value,
  };
}
