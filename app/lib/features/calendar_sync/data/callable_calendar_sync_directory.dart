import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/calendar_feed_link.dart';
import '../model/calendar_provider.dart';
import '../model/provider_availability.dart';
import 'calendar_sync_directory.dart';
import 'calendar_sync_failure_mapper.dart';

/// The calendar sync callables over the Functions SDK. Each answer is parsed
/// rather than cast (`ENG-09`); an answer of the wrong shape is a Function
/// newer or older than this build, and fails as unknown rather than crashing.
final class CallableCalendarSyncDirectory implements CalendarSyncDirectory {
  const CallableCalendarSyncDirectory(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<ProviderAvailability> availableProviders(String householdId) async {
    final result = await _call('listCalendarProviders', {
      'householdId': householdId,
    });
    return ProviderAvailability(
      google: result['google'] == true,
      microsoft: result['microsoft'] == true,
    );
  }

  @override
  Future<Uri> startConnection(
    String householdId,
    CalendarProvider provider,
  ) async {
    final result = await _call('startCalendarConnection', {
      'householdId': householdId,
      'provider': provider.name,
    });
    final url = result['authorizationUrl'];
    final uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null || uri.scheme != 'https') {
      throw UnknownFailure(StateError('no authorization url'));
    }
    return uri;
  }

  @override
  Future<void> connectLink(String householdId, String url) async {
    await _call('connectCalendarLink', {
      'householdId': householdId,
      'url': url,
    });
  }

  @override
  Future<void> syncNow(String householdId, String connectionId) async {
    await _call('syncCalendarConnection', {
      'householdId': householdId,
      'connectionId': connectionId,
    });
  }

  @override
  Future<void> disconnect(String householdId, String connectionId) async {
    await _call('disconnectCalendar', {
      'householdId': householdId,
      'connectionId': connectionId,
    });
  }

  @override
  Future<CalendarFeedLink> shareFeed(String householdId) =>
      _feed('shareCalendarFeed', householdId);

  @override
  Future<CalendarFeedLink> resetFeed(String householdId) =>
      _feed('resetCalendarFeed', householdId);

  Future<CalendarFeedLink> _feed(String name, String householdId) async {
    final url = (await _call(name, {'householdId': householdId}))['url'];
    if (url is! String || url.isEmpty) {
      throw UnknownFailure(StateError('no feed url'));
    }
    return CalendarFeedLink(url);
  }

  Future<Map<Object?, Object?>> _call(
    String name,
    Map<String, Object?> payload,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Object?>(payload);
      final data = result.data;
      return data is Map ? data : const {};
    } on FirebaseFunctionsException catch (error) {
      throw failureFromCalendarSyncCallable(error);
    }
  }
}
