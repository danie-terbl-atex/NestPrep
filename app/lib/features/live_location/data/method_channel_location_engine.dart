import 'package:flutter/services.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/coordinates.dart';
import '../model/family_place.dart';
import 'location_engine.dart';

final class MethodChannelLocationEngine implements LocationEngine {
  MethodChannelLocationEngine({
    this._channel = const MethodChannel(methodChannelName),
    this._events = const EventChannel(eventChannelName),
  });

  static const methodChannelName = 'io.nullstate.nestprep/location';
  static const eventChannelName = 'io.nullstate.nestprep/location/events';

  final MethodChannel _channel;
  final EventChannel _events;

  @override
  Future<void> start(EngineConfig config) async {
    try {
      await _channel.invokeMethod<void>('start', startArguments(config));
    } on PlatformException catch (error) {
      throw LocationFailure(switch (error.code) {
        'noBackground' => LocationProblem.alwaysRefused,
        'noPermission' => LocationProblem.permissionRefused,
        _ => LocationProblem.reportingStopped,
      });
    }
  }

  static Map<String, Object?> startArguments(EngineConfig config) => {
    'householdId': config.householdId,
    'memberId': config.memberId,
    'timeZone': config.timeZone,
    'emulatorHost': config.emulatorHost,
    'firestorePort': config.firestorePort,
    'authPort': config.authPort,
    'foreground': config.foreground,
    'places': placeArguments(config.places),
    'notificationTitle': config.notificationTitle,
    'notificationBody': config.notificationBody,
    'notificationChannelName': config.notificationChannelName,
    'notificationPauseLabel': config.notificationPauseLabel,
  };

  static List<Map<String, Object>> placeArguments(List<FamilyPlace> places) => [
    for (final place in places)
      {
        'id': place.id,
        'latitude': place.centre.latitude,
        'longitude': place.centre.longitude,
        'radiusMetres': place.radiusMetres,
      },
  ];

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  Future<EngineStatus> status() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('status');
    if (raw == null) return EngineStatus.idle;
    return EngineStatus(
      running: raw['running'] == true,
      householdId: raw['householdId'] as String?,
      memberId: raw['memberId'] as String?,
      lastStopReason: _reason(raw['lastStopReason']),
    );
  }

  @override
  Future<void> setForeground({required bool foreground}) =>
      _channel.invokeMethod<void>('setForeground', {'foreground': foreground});

  @override
  Future<void> setPlaces(List<FamilyPlace> places) => _channel
      .invokeMethod<void>('setPlaces', {'places': placeArguments(places)});

  @override
  Future<EnginePermissions> permissions() => _permissions('permissions');

  @override
  Future<EnginePermissions> requestAlways() => _permissions('requestAlways');

  @override
  Future<EnginePermissions> requestMotion() => _permissions('requestMotion');

  @override
  Future<void> openBatterySettings() =>
      _channel.invokeMethod<void>('openBatterySettings');

  @override
  Future<String?> reverseGeocode(Coordinates at) async {
    try {
      return await _channel.invokeMethod<String>('reverseGeocode', {
        'latitude': at.latitude,
        'longitude': at.longitude,
      });
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> ready() => _channel.invokeMethod<void>('ready');

  @override
  Stream<EngineStopReason> get stopped => _events
      .receiveBroadcastStream()
      .where((event) => event is Map && event['event'] == 'stopped')
      .map((event) => _reason((event as Map)['reason']))
      .where((reason) => reason != null)
      .cast<EngineStopReason>();

  Future<EnginePermissions> _permissions(String method) async {
    final raw = await _channel.invokeMapMethod<String, Object?>(method) ?? {};
    return EnginePermissions(
      location:
          LocationAccess.values.asNameMap()[raw['location']] ??
          LocationAccess.denied,
      motion:
          MotionAccess.values.asNameMap()[raw['motion']] ?? MotionAccess.denied,
    );
  }

  static EngineStopReason? _reason(Object? name) =>
      name is String ? EngineStopReason.values.asNameMap()[name] : null;
}
