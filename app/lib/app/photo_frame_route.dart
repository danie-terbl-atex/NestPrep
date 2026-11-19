import 'household_route.dart';

abstract final class PhotoFrameRoute {
  static const segment = 'frames';

  static const path = '${HouseholdRoute.path}/$segment';

  static const photosSegment = 'photos';

  static const photosPath = '$path/$photosSegment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';

  static const linkCodeParameter = 'code';

  static String linkPathFor(String householdId, String code) => Uri(
    path: pathFor(householdId),
    queryParameters: {linkCodeParameter: code},
  ).toString();

  static String photosPathFor(String householdId) =>
      '${pathFor(householdId)}/$photosSegment';
}
