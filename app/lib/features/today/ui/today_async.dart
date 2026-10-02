import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';

/// A Today section's own loading and failure, so one slow read never holds
/// the rest of the day back.
class TodayAsync<T> extends StatelessWidget {
  const TodayAsync({required this.state, required this.builder, super.key});

  final AsyncState<T> state;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncLoading() => const NestSkeleton(height: NestSize.controlLarge),
    AsyncFailure(:final failure) => NestBanner(
      message: AppCopy.failure(failure),
      tone: NestBannerTone.danger,
    ),
    AsyncData(:final value) => builder(context, value),
  };
}
