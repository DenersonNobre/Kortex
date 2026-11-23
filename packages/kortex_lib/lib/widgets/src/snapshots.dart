import 'package:flutter/material.dart';

typedef SnapshotWidgetBuilder<T> = Widget Function(
  BuildContext context,
  AsyncSnapshot<T> snapshot,
);

class SnapshotBuild<T> extends StatelessWidget {
  const SnapshotBuild({
    super.key,
    required this.snapshot,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  final AsyncSnapshot<T> snapshot;
  final SnapshotWidgetBuilder<T> builder;
  final WidgetBuilder? loadingBuilder;
  final SnapshotWidgetBuilder<T>? errorBuilder;
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.none ||
        snapshot.connectionState == ConnectionState.waiting) {
      return loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return errorBuilder?.call(context, snapshot) ??
          Center(
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
          );
    }
    if (snapshot.hasData) return builder(context, snapshot);
    return emptyBuilder?.call(context) ?? const SizedBox.shrink();
  }
}

class FutureSnapshot<T> extends StatelessWidget {
  const FutureSnapshot({
    super.key,
    required this.future,
    required this.builder,
    this.initialData,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  final Future<T> future;
  final T? initialData;
  final SnapshotWidgetBuilder<T> builder;
  final WidgetBuilder? loadingBuilder;
  final SnapshotWidgetBuilder<T>? errorBuilder;
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snapshot) => SnapshotBuild<T>(
        snapshot: snapshot,
        builder: builder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        emptyBuilder: emptyBuilder,
      ),
    );
  }
}

class StreamSnapshot<T> extends StatelessWidget {
  const StreamSnapshot({
    super.key,
    required this.stream,
    required this.builder,
    this.initialData,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  final Stream<T> stream;
  final T? initialData;
  final SnapshotWidgetBuilder<T> builder;
  final WidgetBuilder? loadingBuilder;
  final SnapshotWidgetBuilder<T>? errorBuilder;
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) => SnapshotBuild<T>(
        snapshot: snapshot,
        builder: builder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        emptyBuilder: emptyBuilder,
      ),
    );
  }
}
