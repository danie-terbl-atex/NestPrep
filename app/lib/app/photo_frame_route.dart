import 'household_route.dart';

abstract final class PhotoFrameRoute {
  static const segment = 'frames';

  static const path = '${HouseholdRoute.path}/$segment';

  static const photosSegment = 'photos';

  static const photosPath = '$path/$photosSegment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';

  static String photosPathFor(String householdId) =>
      '${pathFor(householdId)}/$photosSegment';
}
