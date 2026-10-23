import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/welcome_tour/model/tour_place.dart';
import 'package:nestprep/features/welcome_tour/model/tour_stop.dart';
import 'package:nestprep/features/welcome_tour/model/tour_target.dart';
import 'package:nestprep/features/welcome_tour/state/tour_controller.dart';

/// Where the tour is (welcome-tour ADR-0002): stepping, ending, and dropping
/// a stop whose component is not on the screen.
void main() {
  late TourController tour;
  const a = TourStop(TourTarget.tabBar, place: TourPlace.today);
  const b = TourStop(TourTarget.bell, place: TourPlace.today);
  const c = TourStop(TourTarget.lunchDay, place: TourPlace.lunch);

  setUp(() => tour = TourController());
  tearDown(() => tour.dispose());

  test('starts at the first stop and steps forward and back', () {
    tour.start(const [a, b, c]);
    expect(tour.isActive, isTrue);
    expect(tour.current, a);
    tour.back();
    expect(tour.current, a, reason: 'nothing before the first');
    tour
      ..next()
      ..next();
    expect(tour.current, c);
    expect(tour.isLast, isTrue);
    tour.back();
    expect(tour.current, b);
  });

  test('next on the last stop finishes it', () {
    tour.start(const [a, b]);
    tour
      ..next()
      ..next();
    expect(tour.isActive, isFalse);
    expect(tour.lastEnd, TourEnd.finished);
    expect(tour.current, isNull);
  });

  test('skip ends it as skipped, once', () {
    var told = 0;
    tour
      ..start(const [a, b])
      ..addListener(() => told++)
      ..skip()
      ..skip();
    expect(tour.lastEnd, TourEnd.skipped);
    expect(told, 1);
  });

  test('back on the first step is skipping; elsewhere it is a step back', () {
    tour.start(const [a, b]);
    tour.next();
    tour.backOrSkip();
    expect(tour.current, a);
    tour.backOrSkip();
    expect(tour.lastEnd, TourEnd.skipped);
  });

  test(
    'a stop that is not on the screen is dropped, and the count with it',
    () {
      tour.start(const [a, b, c]);
      tour.next();
      tour.dropCurrent();
      expect(tour.current, c);
      expect(tour.count, 2);
      expect(tour.index, 1);
    },
  );

  test('dropped while going back, the step before it shows', () {
    tour.start(const [a, b, c]);
    tour
      ..next()
      ..next()
      ..back();
    tour.dropCurrent();
    expect(tour.current, a);
  });

  test('dropping the last stop finishes the tour', () {
    tour.start(const [a]);
    tour.dropCurrent();
    expect(tour.isActive, isFalse);
    expect(tour.lastEnd, TourEnd.finished);
  });

  test('remembers where it finishes and that it opened itself', () {
    expect(tour.hasAutoStarted, isFalse);
    tour.markAutoStarted();
    tour.start(const [a], finishOn: TourPlace.lunch);
    expect(tour.hasAutoStarted, isTrue);
    expect(tour.finishOn, TourPlace.lunch);
  });

  test('nothing to show starts nothing', () {
    tour.start(const []);
    expect(tour.isActive, isFalse);
  });
}
