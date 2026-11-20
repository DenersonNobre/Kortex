/// Exhaustive rendering of `IKortexAsyncState` (`KortexResourceBuilder`).
///
/// SRP: map `Loading`/`Data`/`Error` to widgets through a Dart 3 `switch`,
/// observing the `resource` with an internal `KortexWatch`. It does NOT load
/// data, retry automatically nor hold state.
///
/// Patterns: Composite (delegated observation) + exhaustive pattern matching.
/// Dependencies: Flutter + the `reactive` layers (no global state).
library;

import 'package:flutter/widgets.dart';

import '../reactive/reactive.dart';
import 'kortex_watch.dart';

/// Builds the error widget with [error] and an optional [stackTrace].
typedef KortexErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// Builds the data widget with [value].
typedef KortexDataWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

/// Renders each state of [resource] with the matching builder.
class KortexResourceBuilder<T> extends StatelessWidget {
  /// Creates the builder with the 3 branches of `IKortexAsyncState`.
  const KortexResourceBuilder({
    super.key,
    required this.resource,
    required this.loading,
    required this.error,
    required this.data,
  });

  /// Observed resource (rebuilds on every state transition).
  final KortexResource<T> resource;

  /// Loading branch (`Loading`, with or without `previousValue`).
  final WidgetBuilder loading;

  /// Error branch (`Error`).
  final KortexErrorWidgetBuilder error;

  /// Success branch (`Data`).
  final KortexDataWidgetBuilder<T> data;

  @override
  Widget build(BuildContext context) => KortexWatch(
    builder: (context, child) {
      final state = resource.state.value;
      return switch (state) {
        KortexAsyncLoading<T>() => loading(context),
        KortexAsyncData<T>(value: final value) => data(context, value),
        KortexAsyncError<T>(error: final failure, stackTrace: final stack) =>
          error(context, failure, stack),
      };
    },
  );
}
