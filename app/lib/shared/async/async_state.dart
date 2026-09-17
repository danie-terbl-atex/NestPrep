import '../failure/app_failure.dart';

/// The state of one live read. A screen switches over it to render loading,
/// error or success; "empty" is `AsyncData` whose value has nothing in it, and
/// the screen renders that case too (`FE-08`).
sealed class AsyncState<T> {
  const AsyncState();
}

final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

final class AsyncData<T> extends AsyncState<T> {
  const AsyncData(this.value);

  final T value;
}

final class AsyncFailure<T> extends AsyncState<T> {
  const AsyncFailure(this.failure);

  final AppFailure failure;
}
