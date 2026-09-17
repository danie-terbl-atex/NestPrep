import 'package:flutter/material.dart';

import '../../shared/async/async_state.dart';
import '../../shared/copy/app_copy.dart';
import '../tokens/nest_motion.dart';
import 'nest_error_view.dart';
import 'nest_loading_view.dart';

/// Renders one `AsyncState` as the four surfaces every live screen has
/// (`FE-08`): loading, error with retry, empty, and data. The screen supplies
/// only the empty and data builders and what "empty" means for its type.
class NestAsyncView<T> extends StatelessWidget {
  const NestAsyncView({
    required this.state,
    required this.isEmpty,
    required this.emptyBuilder,
    required this.dataBuilder,
    required this.onRetry,
    this.loadingRows = 4,
    super.key,
  });

  final AsyncState<T> state;
  final bool Function(T value) isEmpty;
  final WidgetBuilder emptyBuilder;
  final Widget Function(BuildContext context, T value) dataBuilder;
  final VoidCallback onRetry;
  final int loadingRows;

  @override
  Widget build(BuildContext context) {
    final child = switch (state) {
      AsyncLoading() => NestLoadingView(
        key: const ValueKey('loading'),
        rows: loadingRows,
      ),
      AsyncFailure(:final failure) => NestErrorView(
        key: const ValueKey('error'),
        message: AppCopy.failure(failure),
        retryLabel: AppCopy.retry,
        onRetry: onRetry,
      ),
      AsyncData(:final value) when isEmpty(value) => KeyedSubtree(
        key: const ValueKey('empty'),
        child: emptyBuilder(context),
      ),
      AsyncData(:final value) => KeyedSubtree(
        key: const ValueKey('data'),
        child: dataBuilder(context, value),
      ),
    };
    return AnimatedSwitcher(
      duration: NestMotion.of(context).standard,
      switchInCurve: NestMotion.enter,
      switchOutCurve: NestMotion.exit,
      child: child,
    );
  }
}
