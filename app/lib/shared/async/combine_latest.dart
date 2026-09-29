import 'dart:async';

/// Joins two live reads into one: emits [combine] of both latest values once
/// each has emitted, and again whenever either does. An error from either is
/// passed on; cancelling cancels both.
///
/// Extracted on its second use (`ENG-02`): lunch-box's `LunchWeekReader` joins
/// the week's plans with the library, and groceries' meal source joins the
/// week's plan with the meal library, the same way.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A first, B second) combine,
) {
  late final StreamController<R> output;
  StreamSubscription<A>? firstSubscription;
  StreamSubscription<B>? secondSubscription;
  (A,)? latestFirst;
  (B,)? latestSecond;

  void publish() {
    final (a, b) = (latestFirst, latestSecond);
    if (a == null || b == null) return;
    output.add(combine(a.$1, b.$1));
  }

  output = StreamController<R>(
    onListen: () {
      firstSubscription = first.listen((value) {
        latestFirst = (value,);
        publish();
      }, onError: output.addError);
      secondSubscription = second.listen((value) {
        latestSecond = (value,);
        publish();
      }, onError: output.addError);
    },
    onCancel: () async {
      await firstSubscription?.cancel();
      await secondSubscription?.cancel();
    },
  );
  return output.stream;
}
