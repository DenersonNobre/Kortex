import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'state_views.dart';

/// Builds the content for the loaded [value] of an [AsyncPage].
typedef AsyncPageContentBuilder<T> =
    Widget Function(BuildContext context, T value);

/// Single-resource scaffold: loading, error with retry, or content.
///
/// SRP: render [resource] through [contentBuilder], showing [loadingBuilder]
/// (or [Loading]) while in flight and [errorBuilder] (or [ErrorRetryView]
/// with a retry that calls `resource.refresh()`) on failure. It does NOT
/// fetch, cache, own nor dispose [resource] (the caller creates and
/// disposes it; unmount keeps it alive).
class AsyncPage<T> extends StatelessWidget {
  /// Creates the scaffold over an externally owned [resource].
  const AsyncPage({
    super.key,
    required this.resource,
    required this.contentBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.errorMessage,
    this.retryLabel = 'Retry',
    this.refreshOnRetry = true,
  });

  /// Async state source (owned and disposed by the caller).
  final KortexResource<T> resource;

  /// Content builder for the loaded value.
  final AsyncPageContentBuilder<T> contentBuilder;

  /// Overrides the loading branch (defaults to [Loading]).
  final WidgetBuilder? loadingBuilder;

  /// Overrides the error branch (defaults to [ErrorRetryView] with retry).
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Overrides the error message (defaults to the failure text).
  final String? errorMessage;

  /// Tooltip label of the retry affordance.
  final String retryLabel;

  /// Whether tapping retry calls `resource.refresh()` (shows loading again).
  final bool refreshOnRetry;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) {
        switch (resource.state.value) {
          case KortexAsyncLoading<T>():
            final loading = loadingBuilder;
            if (loading != null) return loading(context);
            return const Loading();
          case KortexAsyncError<T>(error: final failure):
            final custom = errorBuilder;
            if (custom != null) return custom(context, failure);
            return ErrorRetryView(
              message: errorMessage ?? failure.toString(),
              onRetry: refreshOnRetry
                  ? () {
                      unawaited(resource.refresh());
                    }
                  : null,
              retryTooltip: retryLabel,
            );
          case KortexAsyncData<T>(value: final value):
            return contentBuilder(context, value);
        }
      },
    );
  }
}
